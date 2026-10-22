"
Bounds-checked little-endian primitives over an owned binary body. No file, network, Unreal or persistence dependency.
"
Class {
	#name : 'BVCLandformBoundedEditBinaryReader',
	#superclass : 'Object',
	#instVars : [
		'bytes',
		'position'
	],
	#category : 'BVC-Landform-Core',
	#package : 'BVC-Landform-Core'
}

{ #category : 'instance creation' }
BVCLandformBoundedEditBinaryReader class >> on: aByteArray [
 ^ self new initializeOn: aByteArray
]

{ #category : 'testing' }
BVCLandformBoundedEditBinaryReader >> atEnd [
 ^ position = (bytes size + 1)
]

{ #category : 'reading' }
BVCLandformBoundedEditBinaryReader >> float32 [
 ^ Float fromIEEE32Bit: (self unsigned: 4)
]

{ #category : 'reading' }
BVCLandformBoundedEditBinaryReader >> float64 [
 ^ Float fromIEEE64BitWord: (self unsigned: 8)
]

{ #category : 'initialization' }
BVCLandformBoundedEditBinaryReader >> initializeOn: aByteArray [
 bytes := aByteArray.
 position := 1.
 ^ self
]

{ #category : 'reading' }
BVCLandformBoundedEditBinaryReader >> signed32 [
 | value |
 value := self unsigned: 4.
 ^ value >= (1 bitShift: 31) ifTrue: [ value - (1 bitShift: 32) ] ifFalse: [ value ]
]

{ #category : 'reading' }
BVCLandformBoundedEditBinaryReader >> take: count [
 | result |
 BVCLandformSampledEditField require: (count >= 0 and: [ position + count - 1 <= bytes size ]) code: 'SAMPLED_CODEC'.
 result := bytes copyFrom: position to: position + count - 1.
 position := position + count.
 ^ result
]

{ #category : 'reading' }
BVCLandformBoundedEditBinaryReader >> unsigned: count [
 | value |
 value := 0.
 (self take: count) withIndexDo: [ :byte :index | value := value bitOr: (byte bitShift: (index - 1) * 8) ].
 ^ value
]
