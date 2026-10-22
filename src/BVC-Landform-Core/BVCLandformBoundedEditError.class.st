"
Signals stable Catalyst bounded-edit validation codes. No durable mutation or publication occurs in decoder/replay construction.
"
Class {
	#name : 'BVCLandformBoundedEditError',
	#superclass : 'Error',
	#category : 'BVC-Landform-Core',
	#package : 'BVC-Landform-Core'
}

{ #category : 'signalling' }
BVCLandformBoundedEditError class >> signalCode: aCode [
 ^ self signal: aCode
]

{ #category : 'accessing' }
BVCLandformBoundedEditError >> code [
 ^ self messageText
]
