"
An immutable decoded sparse Sampled geometry contribution. Preserves explicit validity and IEEE binary32 interpolation/blend/recovery. Body transforms and the metre64/cell32 bridge follow the portable draft contract. Pharo conformance is tested; GemStone platform primitives remain unqualified.
"
Class {
	#name : 'BVCLandformSampledEditField',
	#superclass : 'Object',
	#instVars : [
		'chunkMinimum',
		'chunkMaximum',
		'originMeters',
		'rotationXYZW',
		'spacingMeters',
		'blendMode',
		'applyOnVoid',
		'chunks'
	],
	#category : 'BVC-Landform-Core',
	#package : 'BVC-Landform-Core'
}

{ #category : 'validation' }
BVCLandformSampledEditField class >> base64: text code: code limit: limit [
 | decoded |
 self require: (text isString and: [ text size <= ((limit + 2) // 3 * 4) ]) code: code.
 decoded := [ text base64Decoded ] on: Error do: [ :error | BVCLandformBoundedEditError signalCode: code ].
 self require: (decoded size <= limit and: [ decoded base64Encoded = text ]) code: code.
 ^ decoded
]

{ #category : 'arithmetic' }
BVCLandformSampledEditField class >> blend: before additive: additive removal: removal mode: mode onVoid: onVoid [
 | value argument |
 mode < 2 ifTrue: [
  argument := mode = 0 ifTrue: [ additive ] ifFalse: [ removal ].
  argument ifNil: [ ^ before ].
  before ifNil: [ ^ onVoid ifTrue: [ argument ] ifFalse: [ nil ] ].
  mode = 0 ifTrue: [ ^ before < argument ifTrue: [ before ] ifFalse: [ argument ] ].
  ^ argument < before ifTrue: [ before ] ifFalse: [ argument ] ].
 mode = 2 ifTrue: [
  (before isNil or: [ additive isNil ]) ifTrue: [ ^ nil ].
  ^ additive < before ifTrue: [ before ] ifFalse: [ additive ] ].
 self require: mode = 3 code: 'SAMPLED_MODE_BINDING'.
 value := before.
 additive ifNotNil: [ value := value isNil ifTrue: [ additive ] ifFalse: [ value < additive ifTrue: [ value ] ifFalse: [ additive ] ] ].
 removal ifNotNil: [ value := value isNil ifTrue: [ removal ] ifFalse: [ removal < value ifTrue: [ value ] ifFalse: [ removal ] ] ].
 ^ value
]

{ #category : 'validation' }
BVCLandformSampledEditField class >> contains: outer bounds: inner halo: halo [
 ^ (1 to: 3) allSatisfy: [ :i |
 ((outer at: 'minMeters') at: i) <= (((inner at: 'minMeters') at: i) - halo)
 and: [ ((outer at: 'maxMeters') at: i) >= (((inner at: 'maxMeters') at: i) + halo) ] ]
]

{ #category : 'geometry' }
BVCLandformSampledEditField class >> corners: bounds [
 | points |
 points := OrderedCollection new.
 0 to: 7 do: [ :mask |
  points add: ((1 to: 3) collect: [ :axis |
   ((mask bitShift: 1 - axis) bitAnd: 1) = 0
    ifTrue: [ (bounds at: 'minMeters') at: axis ]
    ifFalse: [ (bounds at: 'maxMeters') at: axis ] ]) ].
 ^ points asArray
]

{ #category : 'geometry' }
BVCLandformSampledEditField class >> cross: a with: b [
 ^ { (a at: 2) * (b at: 3) - ((a at: 3) * (b at: 2)).
 (a at: 3) * (b at: 1) - ((a at: 1) * (b at: 3)).
 (a at: 1) * (b at: 2) - ((a at: 2) * (b at: 1)) }
]

{ #category : 'instance creation' }
BVCLandformSampledEditField class >> decode: bytes [
 ^ self new initializeFromBytes: bytes
]

{ #category : 'validation' }
BVCLandformSampledEditField class >> hash: bytes [
 ^ 'sha256:', (SHA256 hashMessage: bytes) hex asLowercase
]

{ #category : 'validation' }
BVCLandformSampledEditField class >> inside: bounds point: point [
 ^ (1 to: 3) allSatisfy: [ :i |
 ((bounds at: 'minMeters') at: i) <= (point at: i)
 and: [ (point at: i) < ((bounds at: 'maxMeters') at: i) ] ]
]

{ #category : 'validation' }
BVCLandformSampledEditField class >> key: first precedes: second [
 1 to: 3 do: [ :i |
  (first at: i) = (second at: i) ifFalse: [ ^ (first at: i) < (second at: i) ] ].
 ^ false
]

{ #category : 'arithmetic' }
BVCLandformSampledEditField class >> lerp32: first to: second alpha: alpha [
 ^ self round32: first + (self round32: (self round32: alpha) * (self round32: second - first))
]

{ #category : 'validation' }
BVCLandformSampledEditField class >> require: aBoolean code: aCode [
 aBoolean ifFalse: [ BVCLandformBoundedEditError signalCode: aCode ]
]

{ #category : 'geometry' }
BVCLandformSampledEditField class >> rotate: vector quaternion: quaternion inverse: inverse [
 | xyz t u |
 xyz := (1 to: 3) collect: [ :i | inverse ifTrue: [ (quaternion at: i) negated ] ifFalse: [ quaternion at: i ] ].
 t := (self cross: xyz with: vector) collect: [ :n | n * 2.0 ].
 u := self cross: xyz with: t.
 ^ (1 to: 3) collect: [ :i | (vector at: i) + ((quaternion at: 4) * (t at: i)) + (u at: i) ]
]

{ #category : 'arithmetic' }
BVCLandformSampledEditField class >> round32: aNumber [
 ^ Float fromIEEE32Bit: aNumber asFloat asIEEE32BitWord
]

{ #category : 'arithmetic' }
BVCLandformSampledEditField class >> same32: first as: second [
 (first isNil or: [ second isNil ]) ifTrue: [ ^ first == second ].
 ^ first asFloat asIEEE32BitWord = second asFloat asIEEE32BitWord
]

{ #category : 'sampling' }
BVCLandformSampledEditField >> applyGrid: point before: before weight: weight [
 | after w |
 self class require: (weight between: 0.0 and: 1.0) code: 'RECOVERY_WEIGHT'.
 weight = 0 ifTrue: [ ^ before ].
 ((1 to: 3) allSatisfy: [ :i | (chunkMinimum at: i) * 8 <= (point at: i) and: [ (point at: i) < ((chunkMaximum at: i) * 8) ] ]) ifFalse: [ ^ before ].
 after := self class blend: before additive: (self sampleGrid: point channel: 1) removal: (self sampleGrid: point channel: 2) mode: blendMode onVoid: applyOnVoid.
 weight = 1 ifTrue: [ ^ after ].
 self class require: (before notNil and: [ after notNil ]) code: 'PARTIAL_RECOVERY_VOID'.
 w := self class round32: weight.
 ^ self class round32: before + (self class round32: w * (self class round32: after - before))
]

{ #category : 'sampling' }
BVCLandformSampledEditField >> applyMetresAt: point before: before weight: weight [
 | cellBefore after |
 self class require: (point size = 3 and: [ point allSatisfy: [ :n | n isNumber and: [ n asFloat isFinite ] ] ]) code: 'SAMPLED_QUERY_RANGE'.
 before ifNotNil: [ self class require: before asFloat isFinite code: 'SAMPLED_INPUT_RANGE' ].
 cellBefore := before ifNotNil: [ self class round32: before / spacingMeters ].
 cellBefore ifNotNil: [ self class require: (cellBefore isFinite and: [ cellBefore abs <= 1.0e20 ]) code: 'SAMPLED_INPUT_RANGE' ].
 after := self applyGrid: (self gridPosition: point) before: cellBefore weight: (self class round32: weight).
 after ifNotNil: [ self class require: after isFinite code: 'SAMPLED_ARITHMETIC_RANGE' ].
 (self class same32: after as: cellBefore) ifTrue: [ ^ before ].
 ^ after ifNotNil: [ after * spacingMeters ]
]

{ #category : 'accessing' }
BVCLandformSampledEditField >> applyOnVoid [
 ^ applyOnVoid
]

{ #category : 'accessing' }
BVCLandformSampledEditField >> blendMode [
 ^ blendMode
]

{ #category : 'sampling' }
BVCLandformSampledEditField >> bodyPosition: gridPoint [
 | xyz vector t u |
 xyz := rotationXYZW first: 3.
 vector := gridPoint collect: [ :n | n * spacingMeters ].
 t := (self class cross: xyz with: vector) collect: [ :n | n * 2.0 ].
 u := self class cross: xyz with: t.
 ^ (1 to: 3) collect: [ :i | (originMeters at: i) + (vector at: i) + ((rotationXYZW at: 4) * (t at: i)) + (u at: i) ]
]

{ #category : 'accessing' }
BVCLandformSampledEditField >> chunkCount [
 ^ chunks size
]

{ #category : 'accessing' }
BVCLandformSampledEditField >> chunkMaximum [
 ^ chunkMaximum copy
]

{ #category : 'accessing' }
BVCLandformSampledEditField >> chunkMinimum [
 ^ chunkMinimum copy
]

{ #category : 'sampling' }
BVCLandformSampledEditField >> gridPosition: bodyPoint [
 | delta |
 delta := (1 to: 3) collect: [ :i | (bodyPoint at: i) - (originMeters at: i) ].
 ^ (self class rotate: delta quaternion: rotationXYZW inverse: true) collect: [ :n | n / spacingMeters ]
]

{ #category : 'initialization' }
BVCLandformSampledEditField >> initializeFromBytes: raw [
 | body reader modeFlag voidFlag count volume previous key channels mask values value |
 self class require: (raw isKindOf: ByteArray) code: 'SAMPLED_CODEC'.
 self class require: (raw size between: 134 and: 18000000) code: 'SAMPLED_BYTE_BUDGET'.
 body := raw copyFrom: 1 to: raw size - 32.
 self class require: (SHA256 hashMessage: body) = (raw last: 32) code: 'SAMPLED_CODEC'.
 reader := BVCLandformBoundedEditBinaryReader on: body.
 self class require: (reader take: 8) = #[67 76 66 69 0 0 0 1] code: 'SAMPLED_CODEC'.
 chunkMinimum := (1 to: 3) collect: [ :i | reader signed32 ].
 chunkMaximum := (1 to: 3) collect: [ :i | reader signed32 ].
 originMeters := (1 to: 3) collect: [ :i | reader float64 ].
 rotationXYZW := (1 to: 4) collect: [ :i | reader float64 ].
 spacingMeters := reader float64.
 modeFlag := reader unsigned: 1. voidFlag := reader unsigned: 1. count := reader unsigned: 4.
 self class require: (modeFlag <= 3 and: [ voidFlag <= 1 and: [ count <= 4096 ] ]) code: 'SAMPLED_CODEC'.
 blendMode := modeFlag. applyOnVoid := voidFlag = 1.
 self class require: ((originMeters, rotationXYZW, { spacingMeters }) allSatisfy: [ :n | n isFinite ]) code: 'SAMPLED_CODEC'.
 self class require: ((spacingMeters between: (2.0 raisedTo: -20) and: (2.0 raisedTo: 20))) code: 'SAMPLED_CODEC'.
 self class require: (((rotationXYZW collect: [ :n | n squared ]) sum - 1.0) abs < 1.0e-12) code: 'SAMPLED_CODEC'.
 volume := 1.
 1 to: 3 do: [ :i |
  self class require: ((chunkMinimum at: i) < (chunkMaximum at: i)) code: 'SAMPLED_CODEC'.
  volume := volume * ((chunkMaximum at: i) - (chunkMinimum at: i)) ].
 self class require: volume <= 4096 code: 'SAMPLED_DOMAIN_BUDGET'.
 self class require: ((1 to: 3) allSatisfy: [ :i | (chunkMinimum at: i) >= (2 raisedTo: 28) negated and: [ (chunkMaximum at: i) <= ((2 raisedTo: 28) - 1) ] ]) code: 'SAMPLED_GRID_RANGE'.
 chunks := Dictionary new.
 previous := nil.
 1 to: count do: [ :ignored |
  key := (1 to: 3) collect: [ :i | reader signed32 ].
  self class require: ((1 to: 3) allSatisfy: [ :i | (key at: i) >= (chunkMinimum at: i) and: [ (key at: i) < (chunkMaximum at: i) ] ]) code: 'SAMPLED_CODEC'.
  previous ifNotNil: [ self class require: (self class key: previous precedes: key) code: 'SAMPLED_CODEC' ].
  previous := key.
  channels := Array new: 2.
  1 to: 2 do: [ :channel |
   mask := reader unsigned: 64. values := Array new: 512.
   1 to: 512 do: [ :index |
    (mask bitAt: index) = 1 ifTrue: [
     value := reader float32.
     self class require: value isFinite code: 'SAMPLED_CODEC'.
     self class require: value abs <= 1.0e20 code: 'SAMPLED_VALUE_RANGE'.
     values at: index put: value ] ].
   channels at: channel put: values ].
  chunks at: key put: channels ].
 self class require: reader atEnd code: 'SAMPLED_CODEC'.
 ^ self
]

{ #category : 'accessing' }
BVCLandformSampledEditField >> originMeters [
 ^ originMeters copy
]

{ #category : 'accessing' }
BVCLandformSampledEditField >> rotationXYZW [
 ^ rotationXYZW copy
]

{ #category : 'sampling' }
BVCLandformSampledEditField >> sampleGrid: point channel: channel [
 | low axes values pointIndex key chunk index value alpha reduced |
 low := point collect: [ :n | n floor ].
 axes := (1 to: 3) select: [ :i | (point at: i) ~= (low at: i) ].
 values := Array new: (1 bitShift: axes size).
 0 to: values size - 1 do: [ :corner |
  pointIndex := low copy.
  axes withIndexDo: [ :axis :bit |
   pointIndex at: axis put: (pointIndex at: axis) + ((corner bitShift: 1 - bit) bitAnd: 1) ].
  key := pointIndex collect: [ :n | n // 8 ].
  chunk := chunks at: key ifAbsent: [ ^ nil ].
  index := ((pointIndex at: 1) \\ 8) + (8 * ((pointIndex at: 2) \\ 8)) + (64 * ((pointIndex at: 3) \\ 8)) + 1.
  value := (chunk at: channel) at: index.
  value ifNil: [ ^ nil ].
  values at: corner + 1 put: (channel = 2 ifTrue: [ value negated ] ifFalse: [ value ]) ].
 axes do: [ :axis |
  alpha := self class round32: (point at: axis) - (low at: axis).
  reduced := Array new: values size // 2.
  1 to: reduced size do: [ :i | reduced at: i put: (self class lerp32: (values at: 2 * i - 1) to: (values at: 2 * i) alpha: alpha) ].
  values := reduced ].
 ^ channel = 2 ifTrue: [ values first negated ] ifFalse: [ values first ]
]

{ #category : 'accessing' }
BVCLandformSampledEditField >> spacingMeters [
 ^ spacingMeters
]
