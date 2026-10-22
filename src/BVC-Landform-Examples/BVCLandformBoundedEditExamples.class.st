"
GT/Pharo conformance against the user-authorized portable fixture corpus. Covers normalized source-derived bits, typed resources, sparse support, recovery and ordered replay. fixtureDirectory is test configuration only; production classes have no filesystem path dependency.
"
Class {
	#name : 'BVCLandformBoundedEditExamples',
	#superclass : 'TestCase',
	#category : 'BVC-Landform-Examples',
	#package : 'BVC-Landform-Examples'
}

{ #category : 'fixtures' }
BVCLandformBoundedEditExamples >> context [
 ^ ((self json: 'sampled/constant-remove.resource.json') at: 'document') at: 'context'
]

{ #category : 'examples' }
BVCLandformBoundedEditExamples >> exampleBatchReplay [
 <gtExample>
 | replay result baseline |
 replay := self replayNamed: 'mixed-sampled-half' folder: 'sampled'.
 baseline := Dictionary new at: 'distanceMeters' put: -2.0; at: 'materialId' put: 'rock'; at: 'regionId' put: 'basalt'; yourself.
 result := replay sample: #((0 0 598) (3 0 598)) baseline: [ :point | baseline ].
 self assert: (result first at: 'distanceMeters') equals: -1.0.
 self assert: (result first at: 'materialId') equals: 'blue-paint'.
 self assert: (result first at: 'regionId') equals: 'basalt'.
 self assert: (baseline at: 'distanceMeters') equals: -2.0.
 ^ result
]

{ #category : 'examples' }
BVCLandformBoundedEditExamples >> exampleBridgeRecoveryAndVoid [
 <gtExample>
 | payload voidPayload input output |
 payload := self payloadAt: 'sampled/constant-remove.resource.json'.
 #((0 -2) (0.25 -1) (0.5 0) (0.75 1) (1 2)) do: [ :pair |
  output := payload applyAt: #(0 0 598) distance: -2.0 material: 'painted' weight: pair first.
  self assert: output first equals: pair second. self assert: output second equals: 'painted' ].
 input := 2.0000000000000004.
 self assert: (payload applyAt: #(0 0 598) distance: input material: 'painted' weight: 1) first asIEEE64BitWord equals: input asIEEE64BitWord.
 self assert: (payload applyAt: #(3 0 598) distance: -2 material: 'painted' weight: 1) first equals: -2.
 voidPayload := self payloadAt: 'sampled/void-intersect.resource.json'.
 self assert: (voidPayload applyAt: #(0 0 598) distance: -2 material: 'painted' weight: 1) first isNil.
 self reject: [ voidPayload applyAt: #(0 0 598) distance: -2 material: 'painted' weight: 0.5 ] code: 'PARTIAL_RECOVERY_VOID'.
 self assert: voidPayload mayProduceVoid.
 self assert: (self payloadAt: 'sampled/constant-intersect.resource.json') mayProduceVoid not.
 ^ output
]

{ #category : 'examples' }
BVCLandformBoundedEditExamples >> exampleDecodeAllSampledFixtures [
 <gtExample>
 | catalog |
 catalog := self json: 'sampled/catalog.json'.
 (catalog at: 'resources') do: [ :name | self assert: (self fieldNamed: name) chunkCount equals: 8 ].
 ^ (catalog at: 'resources') size
]

{ #category : 'examples' }
BVCLandformBoundedEditExamples >> exampleDenseInterpolation [
 <gtExample>
 | document values resource payload index |
 document := (self json: 'payloads/sampled-remove.resource.json') at: 'document'.
 values := Array new: 125. index := 1.
 0 to: 4 do: [ :z | 0 to: 4 do: [ :y | 0 to: 4 do: [ :x |
  values at: index put: (x + (2 * y) + (3 * z)) asFloat. index := index + 1 ] ] ].
 (document at: 'field') at: 'removal' put: values.
 resource := self resourceForDocument: document.
 payload := BVCLandformBoundedEditPayload fromResource: resource context: self context.
 self assert: (payload sampleDenseAt: #(-1 -1 597) channel: 'removal') equals: 9.0.
 self assert: (payload sampleDenseAt: #(0 0 598) channel: 'removal') equals: 12.0.
 ^ payload
]

{ #category : 'examples' }
BVCLandformBoundedEditExamples >> exampleDirectProceduralReplay [
 <gtExample>
 | cases replay result |
 cases := { 'moon-full' -> -1. 'moon-half' -> -1. 'moon-recovered' -> -2 }.
 cases do: [ :case |
  replay := BVCLandformBoundedEditReplay recipe: (self json: case key, '.recipe.json') resources: #() enabledProfiles: self profiles.
  result := replay replayAt: #(0 0 598) distance: -2.0 material: 'rock'.
  self assert: result first equals: case value. self assert: result second equals: 'blue-paint' ].
 ^ cases size
]

{ #category : 'examples' }
BVCLandformBoundedEditExamples >> exampleFloat64PayloadEnvelopes [
 <gtExample>
 | names |
 names := (self json: 'payloads/catalog.json') at: 'resources'.
 names do: [ :name | self assert: (self payloadAt: 'payloads/', name, '.resource.json') isSparseSampled not ].
 ^ names size
]

{ #category : 'examples' }
BVCLandformBoundedEditExamples >> exampleIEEE32Edges [
 <gtExample>
 | words oneHalf oddHalf |
 words := #(0 16r80000000 1 16r80000001 16r007FFFFF 16r00800000 16r3F800000 16r7F7FFFFF).
 words do: [ :word | self assert: (BVCLandformSampledEditField round32: (Float fromIEEE32Bit: word)) asIEEE32BitWord equals: word ].
 oneHalf := 1.0 + (2.0 raisedTo: -24).
 oddHalf := 1.0 + (3.0 * (2.0 raisedTo: -24)).
 self assert: (BVCLandformSampledEditField round32: oneHalf) asIEEE32BitWord equals: 16r3F800000.
 self assert: (BVCLandformSampledEditField round32: oddHalf) asIEEE32BitWord equals: 16r3F800002.
 ^ words size + 2
]

{ #category : 'examples' }
BVCLandformBoundedEditExamples >> exampleIntegralJSONDimensions [
 <gtExample>
 | document resource payload |
 document := (self json: 'payloads/sampled-remove.resource.json') at: 'document'.
 (document at: 'field') at: 'size' put: #(5.0 5.0 5.0).
 resource := self resourceForDocument: document.
 payload := BVCLandformBoundedEditPayload fromResource: resource context: self context.
 self assert: (payload applyAt: #(0 0 598) distance: -2.0 material: 'rock' weight: 1.0) equals: #(2.0 'rock').
 ^ payload
]

{ #category : 'examples' }
BVCLandformBoundedEditExamples >> exampleMalformedBinary [
 <gtExample>
 | resource raw body changed firstKey |
 resource := self json: 'sampled/constant-remove.resource.json'.
 raw := ((resource at: 'dependencies') first at: 'encodedBase64') base64Decoded.
 self reject: [ BVCLandformSampledEditField decode: (raw first: 130) ] code: 'SAMPLED_BYTE_BUDGET'.
 changed := raw copy. changed at: 179 put: ((changed at: 179) bitXor: 1).
 self reject: [ BVCLandformSampledEditField decode: changed ] code: 'SAMPLED_CODEC'.
 body := raw first: raw size - 32.
 changed := body copy. changed at: 1 put: 0.
 self reject: [ BVCLandformSampledEditField decode: (self sealBody: changed) ] code: 'SAMPLED_CODEC'.
 changed := body copy. changed at: 98 put: 2.
 self reject: [ BVCLandformSampledEditField decode: (self sealBody: changed) ] code: 'SAMPLED_CODEC'.
 changed := body copy. changed replaceFrom: 179 to: 182 with: #[0 0 192 127] startingAt: 1.
 self reject: [ BVCLandformSampledEditField decode: (self sealBody: changed) ] code: 'SAMPLED_CODEC'.
 firstKey := body copyFrom: 103 to: 114.
 changed := body copy. changed replaceFrom: 4339 to: 4350 with: firstKey startingAt: 1.
 self reject: [ BVCLandformSampledEditField decode: (self sealBody: changed) ] code: 'SAMPLED_CODEC'.
 ^ 6
]

{ #category : 'examples' }
BVCLandformBoundedEditExamples >> exampleMixedFloat64RecoveryReplay [
 <gtExample>
 | cases replay result |
 cases := { 'mixed-full' -> -1. 'mixed-half' -> -1. 'mixed-recovered' -> -2 }.
 cases do: [ :case |
  replay := self replayNamed: case key folder: 'payloads'.
  result := replay replayAt: #(0 0 598) distance: -2.0 material: 'rock'.
  self assert: result first equals: case value. self assert: result second equals: 'blue-paint' ].
 ^ cases size
]

{ #category : 'examples' }
BVCLandformBoundedEditExamples >> exampleMixedSampledRecoveryReplay [
 <gtExample>
 | cases replay result |
 cases := { 'mixed-sampled-full' -> -1. 'mixed-sampled-half' -> -1. 'mixed-sampled-recovered' -> -2 }.
 cases do: [ :case |
  replay := self replayNamed: case key folder: 'sampled'.
  result := replay replayAt: #(0 0 598) distance: -2.0 material: 'rock'.
  self assert: result first equals: case value. self assert: result second equals: 'blue-paint'.
  self assert: replay editCount equals: 3.
  self assert: (replay replayAt: #(3 0 598) distance: -2.0 material: 'rock') equals: #(-2.0 'rock') ].
 ^ cases size
]

{ #category : 'examples' }
BVCLandformBoundedEditExamples >> exampleNegativeFloat64Resources [
 <gtExample>
 | cases |
 cases := (self json: 'payloads/catalog.json') at: 'negativeResources'.
 cases do: [ :case |
  self reject: [ self payloadAt: 'payloads/', (case at: 'file') ] code: (case at: 'code') ].
 ^ cases size
]

{ #category : 'examples' }
BVCLandformBoundedEditExamples >> exampleNegativeSampledResources [
 <gtExample>
 | cases |
 cases := (self json: 'sampled/catalog.json') at: 'negativeResources'.
 cases do: [ :case |
  self reject: [ self payloadAt: 'sampled/', (case at: 'file') ] code: (case at: 'code') ].
 ^ cases size
]

{ #category : 'examples' }
BVCLandformBoundedEditExamples >> exampleRawByteImport [
 <gtExample>
 | resource dependency raw binary count payload |
 resource := self json: 'sampled/constant-remove.resource.json'.
 dependency := (resource at: 'dependencies') first.
 raw := (resource at: 'encodedUtf8Base64') base64Decoded.
 binary := (dependency at: 'encodedBase64') base64Decoded.
 count := 0.
 payload := BVCLandformBoundedEditPayload fromPayloadBytes: raw descriptor: (resource at: 'ref')
 binaryResolver: [ :hash |
  count := count + 1.
  self assert: hash equals: ((dependency at: 'ref') at: 'payloadId').
  binary ] context: self context.
 self assert: count equals: 1.
 self assert: (payload applyAt: #(0 0 598) distance: -2 material: 'rock' weight: 1) equals: #(2.0 'rock').
 binary at: 179 put: 0. raw at: 1 put: 0.
 self assert: (payload applyAt: #(0 0 598) distance: -2 material: 'rock' weight: 1) equals: #(2.0 'rock').
 ^ payload
]

{ #category : 'examples' }
BVCLandformBoundedEditExamples >> exampleRawByteImportGuards [
 <gtExample>
 | resource raw binary |
 resource := self json: 'sampled/constant-remove.resource.json'.
 raw := (resource at: 'encodedUtf8Base64') base64Decoded.
 self reject: [ BVCLandformBoundedEditPayload fromPayloadBytes: raw descriptor: (resource at: 'ref') binaryResolver: [ :hash | nil ] context: self context ] code: 'PAYLOAD_DEPENDENCIES'.
 binary := ((resource at: 'dependencies') first at: 'encodedBase64') base64Decoded.
 binary at: 179 put: ((binary at: 179) bitXor: 1).
 self reject: [ BVCLandformBoundedEditPayload fromPayloadBytes: raw descriptor: (resource at: 'ref') binaryResolver: [ :hash | binary ] context: self context ] code: 'SAMPLED_HASH'.
 raw at: 1 put: 0.
 self reject: [ BVCLandformBoundedEditPayload fromPayloadBytes: raw descriptor: (resource at: 'ref') binaryResolver: [ :hash | binary ] context: self context ] code: 'PAYLOAD_HASH'.
 ^ 3
]

{ #category : 'examples' }
BVCLandformBoundedEditExamples >> exampleReplayGuards [
 <gtExample>
 | recipe resources bad missing voidResource selected edit firstKey |
 recipe := self json: 'sampled/mixed-sampled-half.recipe.json'.
 resources := self json: 'sampled/mixed-sampled-half.resources.json'.
 self reject: [ BVCLandformBoundedEditReplay recipe: recipe resources: resources enabledProfiles: #('catalyst.reference.float64/draft') ] code: 'PROFILE_NOT_NEGOTIATED'.
 bad := recipe deepCopy. (bad at: 'profile') at: 'numericProfileId' put: 'catalyst.reference.float64/draft'.
 self reject: [ BVCLandformBoundedEditReplay recipe: bad resources: resources enabledProfiles: self profiles ] code: 'COMPOSITION_PROFILE'.
 missing := resources deepCopy. missing first removeKey: 'dependencies'.
 self reject: [ BVCLandformBoundedEditReplay recipe: recipe resources: missing enabledProfiles: self profiles ] code: 'PAYLOAD_DEPENDENCIES'.
 bad := recipe deepCopy. (((bad at: 'editPlan') at: 'edits') first at: 'recovery') at: 'policyId' put: 'catalyst.recovery.linear-field/draft'.
 self reject: [ BVCLandformBoundedEditReplay recipe: bad resources: resources enabledProfiles: self profiles ] code: 'RECOVERY_PROFILE'.
 bad := recipe deepCopy. (((bad at: 'editPlan') at: 'edits') second at: 'orderKey') at: 'counter' put: '0'.
 self reject: [ BVCLandformBoundedEditReplay recipe: bad resources: resources enabledProfiles: self profiles ] code: 'EDIT_ORDER'.
 bad := recipe deepCopy. ((bad at: 'editPlan') at: 'edits') second at: 'afterEditId' put: 'wrong'.
 self reject: [ BVCLandformBoundedEditReplay recipe: bad resources: resources enabledProfiles: self profiles ] code: 'EDIT_PREDECESSOR'.
 bad := recipe deepCopy. (bad at: 'evaluation') at: 'epochId' put: 'new-epoch'.
 self reject: [ BVCLandformBoundedEditReplay recipe: bad resources: resources enabledProfiles: self profiles ] code: 'TIME_DOMAIN'.
 bad := recipe deepCopy.
 ((((bad at: 'editPlan') at: 'edits') first at: 'readFootprint') at: 'minMeters') at: 1 put: -5.
 self reject: [ BVCLandformBoundedEditReplay recipe: bad resources: resources enabledProfiles: self profiles ] code: 'PAYLOAD_EDIT_SUPPORT_MISMATCH'.
 voidResource := self json: 'sampled/void-intersect.resource.json'.
 bad := recipe deepCopy. selected := resources deepCopy. selected at: 1 put: voidResource.
 (bad at: 'editPayloadRefs') at: 1 put: (voidResource at: 'ref').
 (((bad at: 'editPlan') at: 'edits') first at: 'operation') at: 'payloadId' put: ((voidResource at: 'ref') at: 'payloadId').
 self reject: [ BVCLandformBoundedEditReplay recipe: bad resources: selected enabledProfiles: self profiles ] code: 'FINITE_PROFILE_REQUIRED'.
 ^ 9
]

{ #category : 'examples' }
BVCLandformBoundedEditExamples >> exampleReplayOwnsSnapshot [
 <gtExample>
 | recipe resources replay result metadata |
 recipe := self json: 'sampled/mixed-sampled-half.recipe.json'. resources := self json: 'sampled/mixed-sampled-half.resources.json'.
 replay := BVCLandformBoundedEditReplay recipe: recipe resources: resources enabledProfiles: self profiles.
 (recipe at: 'evaluation') at: 'tick' put: '100'.
 ((resources first at: 'document') at: 'field') at: 'blend' put: 'add'.
 metadata := replay evaluation. metadata at: 'tick' put: '100'.
 self assert: (replay evaluation at: 'tick') equals: '50'.
 result := replay replayAt: #(0 0 598) distance: -2.0 material: 'rock'.
 self assert: result equals: #(-1.0 'blue-paint').
 ^ replay
]

{ #category : 'examples' }
BVCLandformBoundedEditExamples >> exampleResolvedReplay [
 <gtExample>
 | recipe resources binaries jsons count replay result |
 recipe := self json: 'sampled/mixed-sampled-half.recipe.json'.
 resources := self json: 'sampled/mixed-sampled-half.resources.json'.
 binaries := Dictionary new. jsons := Dictionary new. count := 0.
 resources do: [ :resource |
  jsons at: ((resource at: 'ref') at: 'payloadId') put: ((resource at: 'encodedUtf8Base64') base64Decoded).
  (resource at: 'dependencies' ifAbsent: [ #() ]) do: [ :binary |
   binaries at: ((binary at: 'ref') at: 'payloadId') put: ((binary at: 'encodedBase64') base64Decoded) ] ].
 replay := BVCLandformBoundedEditReplay recipe: recipe payloadResolver: [ :ref :bodyContext |
  count := count + 1.
  BVCLandformBoundedEditPayload fromPayloadBytes: (jsons at: (ref at: 'payloadId')) descriptor: ref
   binaryResolver: [ :hash | binaries at: hash ifAbsent: [ nil ] ] context: bodyContext ] enabledProfiles: self profiles.
 self assert: count equals: 3.
 result := replay replayAt: #(0 0 598) distance: -2.0 material: 'rock'.
 self assert: result equals: #(-1.0 'blue-paint').
 self assert: count equals: 3.
 self reject: [ BVCLandformBoundedEditReplay recipe: recipe payloadResolver: [ :ref :bodyContext | nil ] enabledProfiles: self profiles ] code: 'PAYLOAD_MISSING'.
 ^ replay
]

{ #category : 'examples' }
BVCLandformBoundedEditExamples >> exampleRotatedBodyPlacement [
 <gtExample>
 | payload |
 payload := self payloadAt: 'sampled/rotated-remove.resource.json'.
 self assert: (payload applyAt: #(100000 -23000 70000) distance: -2 material: 'rock' weight: 1) equals: #(2.0 'rock').
 ^ payload
]

{ #category : 'examples' }
BVCLandformBoundedEditExamples >> exampleSourceDerivedArithmetic [
 <gtExample>
 | cases fields count payload field before expected point actual mode |
 cases := (self json: 'sampled/source-oracle-cases.json') at: 'cases'.
 fields := Dictionary new. count := 0.
 cases do: [ :case |
  field := fields at: (case at: 'resource') ifAbsentPut: [ self fieldNamed: (case at: 'resource') ].
  before := self floatBits: (case at: 'beforeCellBits').
  expected := self floatBits: (case at: 'expectedCellBits').
  point := field gridPosition: (case at: 'bodyPosition').
  actual := BVCLandformSampledEditField blend: before additive: (field sampleGrid: point channel: 1) removal: (field sampleGrid: point channel: 2) mode: field blendMode onVoid: (case at: 'applyOnVoid').
  self assert: (BVCLandformSampledEditField same32: actual as: expected).
  count := count + 1 ].
 self assert: count equals: 1024.
 ^ count
]

{ #category : 'examples' }
BVCLandformBoundedEditExamples >> exampleSparseCaptureFixture [
 <gtExample>
 | path resource payload |
 path := self fixtureDirectory parent / 'capture' / 'bound-sampled-capture.resource.json'.
 resource := BVCLandformBoundedEditJSONReader read: path contents.
 payload := BVCLandformBoundedEditPayload fromResource: resource context: self context.
 { #(0 0 598) -> 2. #(8 0 598) -> 3. #(-0.5 0 598) -> -2 } do: [ :case |
  self assert: (payload applyAt: case key distance: -2.0 material: 'rock' weight: 1.0) first equals: case value ].
 ^ payload
]

{ #category : 'examples' }
BVCLandformBoundedEditExamples >> exampleStrictJSON [
 <gtExample>
 | parsed |
 parsed := BVCLandformBoundedEditJSONReader read: '[ -0.0, 0.7071067811865476, 1e-40, 18446744073709551615 ]'.
 self assert: parsed first asIEEE32BitWord equals: 16r80000000.
 self assert: (parsed at: 2) asIEEE64BitWord equals: 0.7071067811865476 asIEEE64BitWord.
 self assert: (parsed at: 4) equals: 18446744073709551615.
 self should: [ BVCLandformBoundedEditJSONReader read: '{"x":1,"x":2}' ] raise: BVCLandformBoundedEditError.
 self should: [ BVCLandformBoundedEditJSONReader read: '{} {}' ] raise: BVCLandformBoundedEditError.
 self should: [ BVCLandformBoundedEditJSONReader read: '1.' ] raise: BVCLandformBoundedEditError.
 ^ parsed
]

{ #category : 'examples' }
BVCLandformBoundedEditExamples >> exampleTypedSampledEnvelopes [
 <gtExample>
 | names |
 names := (self json: 'sampled/catalog.json') at: 'resources'.
 names do: [ :name | self assert: (self payloadAt: 'sampled/', name, '.resource.json') isSparseSampled ].
 ^ names size
]

{ #category : 'fixtures' }
BVCLandformBoundedEditExamples >> fieldNamed: name [
 | resource dependency raw |
 resource := self json: 'sampled/', name, '.resource.json'.
 dependency := (resource at: 'dependencies') first.
 raw := BVCLandformSampledEditField base64: (dependency at: 'encodedBase64') code: 'SAMPLED_ENCODING' limit: 18000000.
 ^ BVCLandformSampledEditField decode: raw
]

{ #category : 'examples' }
BVCLandformBoundedEditExamples >> fixtureDirectory [
 "Fixtures belong to the same registered clone as the examples."
 | repository directory |
 repository := IceRepository registry
  detect: [ :each | each name = 'CatalystLandform' ]
  ifNone: [ self error: 'Register the CatalystLandform clone with Iceberg before running examples' ].
 directory := repository repositoryDirectory / 'fixtures' / 'landform'.
 directory isDirectory ifFalse: [ self error: 'CatalystLandform conformance fixtures are missing' ].
 ^ directory
]

{ #category : 'fixtures' }
BVCLandformBoundedEditExamples >> floatBits: hex [
 hex ifNil: [ ^ nil ].
 ^ Float fromIEEE32Bit: ((BVCLandformBoundedEditBinaryReader on: (ByteArray readHexFrom: hex)) unsigned: 4)
]

{ #category : 'fixtures' }
BVCLandformBoundedEditExamples >> json: relativeName [
 ^ BVCLandformBoundedEditJSONReader read: (self fixtureDirectory resolve: relativeName) contents
]

{ #category : 'fixtures' }
BVCLandformBoundedEditExamples >> payloadAt: relativeName [
 ^ BVCLandformBoundedEditPayload fromResource: (self json: relativeName) context: self context
]

{ #category : 'fixtures' }
BVCLandformBoundedEditExamples >> profiles [
 ^ #('catalyst.reference.float64/draft' 'catalyst.vpp-sampled.float32/draft' 'catalyst.composition.meter64-cell32/draft')
]

{ #category : 'assertions' }
BVCLandformBoundedEditExamples >> reject: operation code: expected [
 [ operation value. self fail: 'Expected ', expected ]
  on: BVCLandformBoundedEditError do: [ :error | self assert: error code equals: expected ]
]

{ #category : 'examples' }
BVCLandformBoundedEditExamples >> replayNamed: name folder: folder [
 ^ BVCLandformBoundedEditReplay recipe: (self json: folder, '/', name, '.recipe.json')
 resources: (self json: folder, '/', name, '.resources.json') enabledProfiles: self profiles
]

{ #category : 'fixtures' }
BVCLandformBoundedEditExamples >> resourceForDocument: document [
 | bytes |
 bytes := (NeoJSONWriter toString: document) utf8Encoded.
 ^ Dictionary new
  at: 'ref' put: (Dictionary new at: 'payloadId' put: (BVCLandformSampledEditField hash: bytes);
   at: 'mediaType' put: 'application/json'; at: 'codecId' put: 'catalyst.bounded-edit-payload.json/draft';
   at: 'decodedBytes' put: bytes size asString; at: 'dependencyRefs' put: #(); yourself);
  at: 'document' put: document;
  at: 'encodedUtf8Base64' put: bytes base64Encoded; yourself
]

{ #category : 'fixtures' }
BVCLandformBoundedEditExamples >> sealBody: bytes [
 ^ bytes, (SHA256 hashMessage: bytes)
]
