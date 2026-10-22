"
A scoped NeoJSONReader for bounded-edit records: duplicate keys and trailing data fail; numbers retain IEEE binary64 parsing and signed zero. GT/Pharo platform implementation, with bounded input and numeric token work.
"
Class {
	#name : 'BVCLandformBoundedEditJSONReader',
	#superclass : 'NeoJSONReader',
	#category : 'BVC-Landform-Core',
	#package : 'BVC-Landform-Core'
}

{ #category : 'reading' }
BVCLandformBoundedEditJSONReader class >> read: text [
 | reader result |
 BVCLandformSampledEditField require: (text isString and: [ text size <= 2000000 ]) code: 'PAYLOAD_JSON'.
 reader := self on: text readStream.
 [ result := reader next. reader failIfNotAtEnd ] on: NeoJSONParseError do: [ :error | BVCLandformBoundedEditError signalCode: 'PAYLOAD_JSON' ].
 ^ result
]

{ #category : 'parsing' }
BVCLandformBoundedEditJSONReader >> parseMap [
 | map |
 map := self mapClass new.
 self parseMapKeysAndValuesDo: [ :key :value |
  (map includesKey: key) ifTrue: [ BVCLandformBoundedEditError signalCode: 'DUPLICATE_JSON_KEY' ].
  map at: key put: value ].
 ^ map
]

{ #category : 'parsing' }
BVCLandformBoundedEditJSONReader >> parseNumber [
 | token stream exponentStart exponent value floating |
 token := String streamContents: [ :out |
  [ readStream atEnd not and: [ '-+0123456789.eE' includes: readStream peek ] ]
   whileTrue: [ out nextPut: readStream next.
    out position > 160 ifTrue: [ BVCLandformBoundedEditError signalCode: 'PAYLOAD_JSON' ] ] ].
 stream := token readStream.
 stream peekFor: $-.
 self requireDigitOn: stream.
 (stream peekFor: $0)
  ifFalse: [ [ stream atEnd not and: [ stream peek between: $0 and: $9 ] ] whileTrue: [ stream next ] ].
 floating := stream peekFor: $..
 floating ifTrue: [ self requireDigitOn: stream.
  [ stream atEnd not and: [ stream peek between: $0 and: $9 ] ] whileTrue: [ stream next ] ].
 (stream peekFor: $e) | (stream peekFor: $E) ifTrue: [
  floating := true. exponentStart := stream position.
  (stream peekFor: $+) ifFalse: [ stream peekFor: $- ].
  self requireDigitOn: stream.
  [ stream atEnd not and: [ stream peek between: $0 and: $9 ] ] whileTrue: [ stream next ].
  exponent := Integer readFrom: (token copyFrom: exponentStart + 1 to: stream position) readStream.
  exponent abs > 10000 ifTrue: [ BVCLandformBoundedEditError signalCode: 'PAYLOAD_JSON' ] ].
 stream atEnd ifFalse: [ BVCLandformBoundedEditError signalCode: 'PAYLOAD_JSON' ].
 value := [ floating ifTrue: [ Float readFrom: token readStream ] ifFalse: [ Integer readFrom: token readStream ] ]
  on: Error do: [ :error | BVCLandformBoundedEditError signalCode: 'PAYLOAD_JSON' ].
 (value isFloat and: [ value isFinite not ]) ifTrue: [ BVCLandformBoundedEditError signalCode: 'NONFINITE' ].
 self consumeWhitespace.
 ^ value
]

{ #category : 'parsing' }
BVCLandformBoundedEditJSONReader >> requireDigitOn: stream [
 (stream atEnd or: [ (stream peek between: $0 and: $9) not ]) ifTrue: [ BVCLandformBoundedEditError signalCode: 'PAYLOAD_JSON' ]
]
