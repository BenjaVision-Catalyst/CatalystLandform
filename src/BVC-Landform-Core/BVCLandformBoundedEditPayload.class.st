"
Owns a verified typed bounded edit payload and its decoded Sampled/dense/procedural state. Supports raw JSON/binary resource resolution and fixture catalogs through shared validation. Resource identities, frames and support are checked before replay; this object grants no edit authority.
"
Class {
	#name : 'BVCLandformBoundedEditPayload',
	#superclass : 'Object',
	#instVars : [
		'document',
		'field',
		'payloadReference'
	],
	#category : 'BVC-Landform-Core',
	#package : 'BVC-Landform-Core'
}

{ #category : 'sampling' }
BVCLandformBoundedEditPayload class >> applyProcedure: operation at: point distance: before material: material weight: weight [
 | distance radius signed after afterMaterial name |
 after := before. afterMaterial := material.
 before ifNotNil: [
  distance := (((1 to: 3) collect: [ :i | ((point at: i) - ((operation at: 'centerMeters') at: i)) squared ]) sum) sqrt.
  signed := distance - (operation at: 'radiusMeters').
  name := operation at: 'operatorId'.
  name = 'catalyst.edit.sphere-remove/draft' ifTrue: [ after := before >= signed negated ifTrue: [ before ] ifFalse: [ signed negated ] ].
  name = 'catalyst.edit.sphere-add/draft' ifTrue: [
   signed < before ifTrue: [ after := signed. afterMaterial := operation at: 'materialId' ] ].
  name = 'catalyst.edit.paint-volume/draft' ifTrue: [ signed <= 0 ifTrue: [ afterMaterial := operation at: 'materialId' ] ] ].
 weight = 1 ifTrue: [ ^ { after. afterMaterial } ].
 self require: (before notNil and: [ after notNil ]) code: 'PARTIAL_RECOVERY_VOID'.
 ^ { before + (weight * (after - before)). material }
]

{ #category : 'validation' }
BVCLandformBoundedEditPayload class >> bounds: bounds frame: frame [
 self keys: bounds required: #('frameId' 'minMeters' 'maxMeters') optional: #().
 self identifier: (bounds at: 'frameId').
 self vector: (bounds at: 'minMeters') size: 3. self vector: (bounds at: 'maxMeters') size: 3.
 self require: (bounds at: 'frameId') = frame code: 'PAYLOAD_FRAME'.
 self require: ((1 to: 3) allSatisfy: [ :i | ((bounds at: 'minMeters') at: i) < ((bounds at: 'maxMeters') at: i) ]) code: 'PAYLOAD_BOUNDS'
]

{ #category : 'validation' }
BVCLandformBoundedEditPayload class >> capture: capture [
 | reads ids |
 self keys: capture required: #('kind') optional: #('sceneToken' 'evaluation' 'readRevisions').
 (capture at: 'kind') = 'independent' ifTrue: [ ^ self keys: capture required: #('kind') optional: #() ].
 self require: (capture at: 'kind') = 'predecessorDependent' code: 'SCHEMA'.
 self keys: capture required: #('kind' 'sceneToken' 'evaluation' 'readRevisions') optional: #().
 self identifier: (capture at: 'sceneToken'). self time: (capture at: 'evaluation').
 reads := capture at: 'readRevisions'.
 self require: ((reads isKindOf: Array) and: [ reads notEmpty and: [ reads size <= 10000 ] ]) code: 'SCHEMA'.
 ids := Set new.
 reads do: [ :read |
  self keys: read required: #('cellId' 'revision') optional: #().
  self identifier: (read at: 'cellId'). self uint64: (read at: 'revision').
  self require: (ids includes: (read at: 'cellId')) not code: 'PAYLOAD_DUPLICATE_READ'.
  ids add: (read at: 'cellId') ]
]

{ #category : 'validation' }
BVCLandformBoundedEditPayload class >> context: context [
 self keys: context required: #('bodyId' 'bodyFrameId' 'definitionRevision') optional: #().
 self identifier: (context at: 'bodyId'). self identifier: (context at: 'bodyFrameId').
 self uint64: (context at: 'definitionRevision')
]

{ #category : 'validation' }
BVCLandformBoundedEditPayload class >> denseField: field [
 | size count |
 self keys: field required: #('originMeters' 'rotationXYZW' 'spacingMeters' 'size' 'sampleOrder' 'interpolation' 'distanceUnit' 'additive' 'removal' 'removalConvention' 'blend' 'applyOnVoid') optional: #().
 self vector: (field at: 'originMeters') size: 3. self vector: (field at: 'rotationXYZW') size: 4.
 self finite: (field at: 'spacingMeters'). self require: (field at: 'spacingMeters') > 0 code: 'SCHEMA'.
 size := field at: 'size'. self vector: size size: 3.
 self require: (size allSatisfy: [ :n | (self integerNumber: n) and: [ n between: 2 and: 64 ] ]) code: 'SCHEMA'.
 count := size inject: 1 into: [ :n :axis | n * axis ].
 #('additive' 'removal') do: [ :key |
  self require: (((field at: key) isKindOf: Array) and: [ (field at: key) size = count ]) code: 'GRID_SAMPLE_COUNT'.
  (field at: key) do: [ :value | value ifNotNil: [ self finite: value ] ] ].
 self require: (field at: 'sampleOrder') = 'xFastest' code: 'SCHEMA'.
 self require: (field at: 'interpolation') = 'trilinearFloat64' code: 'SCHEMA'.
 self require: (field at: 'distanceUnit') = 'meter' code: 'SCHEMA'.
 self require: (field at: 'removalConvention') = 'signedMaxArgument' code: 'SCHEMA'.
 self require: (#('add' 'remove' 'intersect' 'override') includes: (field at: 'blend')) code: 'SCHEMA'.
 self require: (#(true false) includes: (field at: 'applyOnVoid')) code: 'SCHEMA'
]

{ #category : 'validation' }
BVCLandformBoundedEditPayload class >> finite: number [
 self require: ((number isInteger or: [ number isFloat ]) and: [ number asFloat isFinite ]) code: 'SCHEMA'
]

{ #category : 'instance creation' }
BVCLandformBoundedEditPayload class >> fromPayloadBytes: bytes descriptor: descriptor binaryResolver: resolver context: context [
 ^ self new initializeFromPayloadBytes: bytes descriptor: descriptor binaryResolver: resolver context: context
]

{ #category : 'instance creation' }
BVCLandformBoundedEditPayload class >> fromResource: resource context: context [
 ^ self new initializeFromResource: resource context: context
]

{ #category : 'validation' }
BVCLandformBoundedEditPayload class >> identifier: string [
 self require: (string isString and: [ (string size between: 1 and: 160) and: [
 string allSatisfy: [ :char | 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._:/-' includes: char ] ] ]) code: 'SCHEMA'
]

{ #category : 'validation' }
BVCLandformBoundedEditPayload class >> integerNumber: number [
 ^ number isInteger or: [ number isFloat and: [ number isFinite and: [ number = number truncated ] ] ]
]

{ #category : 'validation' }
BVCLandformBoundedEditPayload class >> integerString: string minimum: minimum maximum: maximum [
 | value digits |
 self require: (string isString and: [ string size between: 1 and: 21 ]) code: 'SCHEMA'.
 digits := string first = $- ifTrue: [ string allButFirst ] ifFalse: [ string ].
 self require: (digits notEmpty and: [ digits allSatisfy: [ :char | char between: $0 and: $9 ] ]) code: 'SCHEMA'.
 self require: (string = '0' or: [ digits first ~= $0 ]) code: 'SCHEMA'.
 value := Integer readFrom: string readStream.
 self require: (value between: minimum and: maximum) code: 'SCHEMA'.
 ^ value
]

{ #category : 'validation' }
BVCLandformBoundedEditPayload class >> keys: dictionary required: required optional: optional [
 self require: (dictionary isKindOf: Dictionary) code: 'SCHEMA'.
 self require: (required allSatisfy: [ :key | dictionary includesKey: key ]) code: 'SCHEMA'.
 self require: (dictionary keys allSatisfy: [ :key | (required includes: key) or: [ optional includes: key ] ]) code: 'SCHEMA'
]

{ #category : 'validation' }
BVCLandformBoundedEditPayload class >> nativeField: field [
 | domain |
 self keys: field required: #('storage' 'data' 'originMeters' 'rotationXYZW' 'spacingMeters' 'chunkDomain' 'chunkCount' 'chunkSide' 'sampleOrder' 'distanceUnit' 'interpolation' 'validity' 'removalConvention' 'blend' 'applyOnVoid' 'bridgeId') optional: #().
 self require: (field at: 'storage') = 'sparseMaskedFloat32' code: 'SCHEMA'.
 self reference: (field at: 'data') binary: true.
 self vector: (field at: 'originMeters') size: 3. self vector: (field at: 'rotationXYZW') size: 4.
 self finite: (field at: 'spacingMeters').
 self require: ((field at: 'spacingMeters') between: (2.0 raisedTo: -20) and: (2.0 raisedTo: 20)) code: 'SCHEMA'.
 domain := field at: 'chunkDomain'. self keys: domain required: #('minInclusive' 'maxExclusive') optional: #().
 domain values do: [ :vector |
  self vector: vector size: 3.
  self require: (vector allSatisfy: [ :n | (self integerNumber: n) and: [ n between: (1 bitShift: 31) negated and: (1 bitShift: 31) - 1 ] ]) code: 'SCHEMA' ].
 self require: ((self integerNumber: (field at: 'chunkCount')) and: [ (field at: 'chunkCount') between: 0 and: 4096 ]) code: 'SCHEMA'.
 self require: (field at: 'chunkSide') = 8 code: 'SCHEMA'.
 self require: (field at: 'sampleOrder') = 'xFastest' code: 'SCHEMA'.
 self require: (field at: 'distanceUnit') = 'gridCell' code: 'SCHEMA'.
 self require: (field at: 'interpolation') = 'vppSampledFloat32NoFMA' code: 'SCHEMA'.
 self require: (field at: 'validity') = 'perChannel512BitMask' code: 'SCHEMA'.
 self require: (field at: 'removalConvention') = 'signedMaxArgumentRestoreBeforeInterpolation' code: 'SCHEMA'.
 self require: (field at: 'bridgeId') = 'catalyst.bridge.meter64-cell32/draft' code: 'SCHEMA'.
 self require: (#('add' 'remove' 'intersect' 'override') includes: (field at: 'blend')) code: 'SCHEMA'.
 self require: (#(true false) includes: (field at: 'applyOnVoid')) code: 'SCHEMA'
]

{ #category : 'validation' }
BVCLandformBoundedEditPayload class >> operation: operation [
 | name keys |
 self keys: operation required: #('operatorId' 'centerMeters' 'radiusMeters') optional: #('materialId').
 name := operation at: 'operatorId'.
 self require: (#('catalyst.edit.sphere-remove/draft' 'catalyst.edit.sphere-add/draft' 'catalyst.edit.paint-volume/draft') includes: name) code: 'SCHEMA'.
 keys := name = 'catalyst.edit.sphere-remove/draft'
  ifTrue: [ #('operatorId' 'centerMeters' 'radiusMeters') ]
  ifFalse: [ #('operatorId' 'centerMeters' 'radiusMeters' 'materialId') ].
 self keys: operation required: keys optional: #().
 self vector: (operation at: 'centerMeters') size: 3. self finite: (operation at: 'radiusMeters').
 self require: (operation at: 'radiusMeters') > 0 code: 'SCHEMA'.
 operation at: 'materialId' ifPresent: [ :material | self identifier: material ]
]

{ #category : 'validation' }
BVCLandformBoundedEditPayload class >> reference: ref binary: binary [
 | hash dependencies |
 self keys: ref required: #('payloadId' 'mediaType' 'codecId' 'decodedBytes' 'dependencyRefs') optional: #().
 hash := ref at: 'payloadId'.
 self require: (hash isString and: [ hash size = 71 and: [ (hash beginsWith: 'sha256:') and: [ (hash allButFirst: 7) allSatisfy: [ :c | '0123456789abcdef' includes: c ] ] ] ]) code: 'SCHEMA'.
 self require: (ref at: 'mediaType') = (binary ifTrue: [ 'application/octet-stream' ] ifFalse: [ 'application/json' ]) code: 'SCHEMA'.
 self require: (ref at: 'codecId') = (binary ifTrue: [ 'catalyst.bounded-edit.masked-float32-le/draft' ] ifFalse: [ 'catalyst.bounded-edit-payload.json/draft' ]) code: 'SCHEMA'.
 self uint64: (ref at: 'decodedBytes').
 dependencies := ref at: 'dependencyRefs'.
 self require: ((dependencies isKindOf: Array) and: [ dependencies size <= (binary ifTrue: [ 0 ] ifFalse: [ 1 ]) ]) code: 'SCHEMA'.
 dependencies do: [ :dependency | self require: (dependency isString and: [ dependency size = 71 and: [ dependency beginsWith: 'sha256:' ] ]) code: 'SCHEMA' ]
]

{ #category : 'validation' }
BVCLandformBoundedEditPayload class >> require: condition code: code [
 ^ BVCLandformSampledEditField require: condition code: code
]

{ #category : 'validation' }
BVCLandformBoundedEditPayload class >> sameJSON: a as: b [
 (a isNumber and: [ b isNumber ]) ifTrue: [
  (a isInteger and: [ b isInteger ]) ifTrue: [ ^ a = b ].
  ^ a asFloat asIEEE64BitWord = b asFloat asIEEE64BitWord ].
 (a isKindOf: Dictionary) ifTrue: [
  ^ (b isKindOf: Dictionary) and: [ a keys asSet = b keys asSet and: [ a keys allSatisfy: [ :key | self sameJSON: (a at: key) as: (b at: key) ] ] ] ].
 (a isKindOf: Array) ifTrue: [
  ^ (b isKindOf: Array) and: [ a size = b size and: [ (1 to: a size) allSatisfy: [ :i | self sameJSON: (a at: i) as: (b at: i) ] ] ] ].
 ^ a = b
]

{ #category : 'validation' }
BVCLandformBoundedEditPayload class >> time: time [
 self keys: time required: #('domainId' 'epochId' 'tick') optional: #().
 self identifier: (time at: 'domainId'). self identifier: (time at: 'epochId').
 self integerString: (time at: 'tick') minimum: (1 bitShift: 63) negated maximum: (1 bitShift: 63) - 1
]

{ #category : 'validation' }
BVCLandformBoundedEditPayload class >> uint64: string [
 ^ self integerString: string minimum: 0 maximum: (1 bitShift: 64) - 1
]

{ #category : 'validation' }
BVCLandformBoundedEditPayload class >> vector: vector size: size [
 self require: ((vector isKindOf: Array) and: [ vector size = size ]) code: 'SCHEMA'.
 vector do: [ :number | self finite: number ]
]

{ #category : 'sampling' }
BVCLandformBoundedEditPayload >> applyAt: point distance: before material: material weight: weight [
 | f mode after additive removal onVoid |
 self class require: ((weight isNumber and: [ weight asFloat isFinite ]) and: [ weight between: 0.0 and: 1.0 ]) code: 'RECOVERY_WEIGHT'.
 (weight = 0 or: [ (BVCLandformSampledEditField inside: (document at: 'contributionClip') point: point) not ]) ifTrue: [ ^ { before. material } ].
 self isSparseSampled ifTrue: [ ^ { (field applyMetresAt: point before: before weight: weight). material } ].
 (weight ~= 1 and: [ self channels ~= #('geometry') ]) ifTrue: [ BVCLandformBoundedEditError signalCode: 'RECOVERY_CHANNEL_UNSUPPORTED' ].
 self isProcedural ifTrue: [ ^ self class applyProcedure: (document at: 'procedure') at: point distance: before material: material weight: weight ].
 f := document at: 'field'. mode := f at: 'blend'. onVoid := f at: 'applyOnVoid'. after := before.
 (mode = 'add' or: [ mode = 'intersect' or: [ mode = 'override' ] ]) ifTrue: [ additive := self sampleDenseAt: point channel: 'additive' ].
 (mode = 'remove' or: [ mode = 'override' ]) ifTrue: [ removal := self sampleDenseAt: point channel: 'removal' ].
 mode = 'intersect' ifTrue: [ after := (before isNil or: [ additive isNil ]) ifTrue: [ nil ] ifFalse: [ before >= additive ifTrue: [ before ] ifFalse: [ additive ] ] ].
 mode = 'add' ifTrue: [ additive ifNotNil: [ after := before isNil ifTrue: [ onVoid ifTrue: [ additive ] ifFalse: [ nil ] ] ifFalse: [ before <= additive ifTrue: [ before ] ifFalse: [ additive ] ] ] ].
 mode = 'remove' ifTrue: [ removal ifNotNil: [ after := before isNil ifTrue: [ onVoid ifTrue: [ removal ] ifFalse: [ nil ] ] ifFalse: [ before >= removal ifTrue: [ before ] ifFalse: [ removal ] ] ] ].
 mode = 'override' ifTrue: [
  additive ifNotNil: [ after := after isNil ifTrue: [ additive ] ifFalse: [ after <= additive ifTrue: [ after ] ifFalse: [ additive ] ] ].
  removal ifNotNil: [ after := after isNil ifTrue: [ removal ] ifFalse: [ after >= removal ifTrue: [ after ] ifFalse: [ removal ] ] ] ].
 weight = 1 ifTrue: [ ^ { after. material } ].
 self class require: (before notNil and: [ after notNil ]) code: 'PARTIAL_RECOVERY_VOID'.
 ^ { before + (weight * (after - before)). material }
]

{ #category : 'accessing' }
BVCLandformBoundedEditPayload >> channels [
 ^ (document at: 'channels') copy
]

{ #category : 'sampling' }
BVCLandformBoundedEditPayload >> denseGridPosition: point [
 | f delta |
 f := document at: 'field'.
 delta := (1 to: 3) collect: [ :i | (point at: i) - ((f at: 'originMeters') at: i) ].
 ^ (BVCLandformSampledEditField rotate: delta quaternion: (f at: 'rotationXYZW') inverse: true) collect: [ :n | n / (f at: 'spacingMeters') ]
]

{ #category : 'accessing' }
BVCLandformBoundedEditPayload >> document [
 ^ document deepCopy
]

{ #category : 'initialization' }
BVCLandformBoundedEditPayload >> initializeFromPayloadBytes: raw descriptor: descriptor binaryResolver: resolver context: context [
 | expected binaryRef binary |
 self class context: context. self class reference: descriptor binary: false.
 self class require: (raw isKindOf: ByteArray) code: 'PAYLOAD_JSON'.
 self class require: (raw size between: 1 and: 2000000) code: 'PAYLOAD_JSON'.
 self class require: (BVCLandformSampledEditField hash: raw) = (descriptor at: 'payloadId') code: 'PAYLOAD_HASH'.
 self class require: raw size = (self class uint64: (descriptor at: 'decodedBytes')) code: 'PAYLOAD_LENGTH'.
 document := [ BVCLandformBoundedEditJSONReader read: raw utf8Decoded ] on: ZnCharacterEncodingError do: [ :error | BVCLandformBoundedEditError signalCode: 'PAYLOAD_JSON' ].
 self validateDocumentFor: context.
 expected := self isSparseSampled ifTrue: [ { ((document at: 'field') at: 'data') at: 'payloadId' } ] ifFalse: [ #() ].
 self class require: (descriptor at: 'dependencyRefs') = expected code: 'PAYLOAD_DEPENDENCIES'.
 self isSparseSampled ifTrue: [
  binaryRef := (document at: 'field') at: 'data'.
  binary := resolver value: (binaryRef at: 'payloadId').
  self initializeNativeBytes: binary descriptor: binaryRef ]
 ifFalse: [ self isProcedural ifFalse: [
  self validateDenseSupport. field := (document at: 'field') copy.
  field at: 'size' put: ((field at: 'size') collect: [ :n | n asInteger ]) ] ].
 payloadReference := descriptor deepCopy.
 ^ self
]

{ #category : 'initialization' }
BVCLandformBoundedEditPayload >> initializeFromResource: resource context: context [
 | ref raw parsed dependencies expected dependency binaryRef binary encoded |
 self class context: context.
 self class keys: resource required: #('ref' 'document' 'encodedUtf8Base64') optional: #('dependencies').
 document := (resource at: 'document') deepCopy.
 self validateDocumentFor: context.
 ref := resource at: 'ref'. self class reference: ref binary: false.
 raw := BVCLandformSampledEditField base64: (resource at: 'encodedUtf8Base64') code: 'PAYLOAD_ENCODING' limit: 2000000.
 self class require: (BVCLandformSampledEditField hash: raw) = (ref at: 'payloadId') code: 'PAYLOAD_HASH'.
 self class require: raw size = (self class uint64: (ref at: 'decodedBytes')) code: 'PAYLOAD_LENGTH'.
 parsed := [ BVCLandformBoundedEditJSONReader read: raw utf8Decoded ] on: ZnCharacterEncodingError do: [ :error | BVCLandformBoundedEditError signalCode: 'PAYLOAD_JSON' ].
 self class require: (self class sameJSON: parsed as: document) code: 'PAYLOAD_DOCUMENT_MISMATCH'.
 dependencies := resource at: 'dependencies' ifAbsent: [ #() ].
 expected := self isSparseSampled ifTrue: [ { ((document at: 'field') at: 'data') at: 'payloadId' } ] ifFalse: [ #() ].
 self class require: (ref at: 'dependencyRefs') = expected code: 'PAYLOAD_DEPENDENCIES'.
 self class require: (dependencies isKindOf: Array) code: 'SCHEMA'.
 dependencies do: [ :entry |
  self class keys: entry required: #('ref' 'encodedBase64') optional: #().
  self class reference: (entry at: 'ref') binary: true ].
 self class require: (dependencies collect: [ :r | (r at: 'ref') at: 'payloadId' ]) = expected code: 'PAYLOAD_DEPENDENCIES'.
 self isSparseSampled ifTrue: [
  dependency := dependencies first.
  self class keys: dependency required: #('ref' 'encodedBase64') optional: #().
  binaryRef := dependency at: 'ref'. self class reference: binaryRef binary: true.
  self class require: binaryRef = ((document at: 'field') at: 'data') code: 'SAMPLED_RESOURCE_BINDING'.
  encoded := dependency at: 'encodedBase64'.
  self class require: encoded size <= (4 * ((18000000 + 2) // 3)) code: 'SAMPLED_BYTE_BUDGET'.
  binary := BVCLandformSampledEditField base64: encoded code: 'SAMPLED_ENCODING' limit: 18000000.
  self initializeNativeBytes: binary descriptor: binaryRef ] ifFalse: [ self isProcedural ifFalse: [ self validateDenseSupport. field := (document at: 'field') copy. field at: 'size' put: ((field at: 'size') collect: [ :n | n asInteger ]) ] ].
 payloadReference := ref deepCopy.
 ^ self
]

{ #category : 'initialization' }
BVCLandformBoundedEditPayload >> initializeNativeBytes: binary descriptor: binaryRef [
 self class reference: binaryRef binary: true.
 self class require: (binary isKindOf: ByteArray) code: 'PAYLOAD_DEPENDENCIES'.
 self class require: (binary size between: 1 and: 18000000) code: 'SAMPLED_BYTE_BUDGET'.
 self class require: binary size = (self class uint64: (binaryRef at: 'decodedBytes')) code: 'SAMPLED_LENGTH'.
 self class require: (BVCLandformSampledEditField hash: binary) = (binaryRef at: 'payloadId') code: 'SAMPLED_HASH'.
 field := BVCLandformSampledEditField decode: binary.
 self validateNativeBinding
]

{ #category : 'testing' }
BVCLandformBoundedEditPayload >> isProcedural [
 ^ (document at: 'representation') = 'procedural'
]

{ #category : 'testing' }
BVCLandformBoundedEditPayload >> isSparseSampled [
 ^ (document at: 'numericProfileId') = 'catalyst.vpp-sampled.float32/draft'
]

{ #category : 'validation' }
BVCLandformBoundedEditPayload >> mayProduceVoid [
 | descriptor points lower upper count |
 self isProcedural ifTrue: [ ^ false ].
 descriptor := document at: 'field'.
 (descriptor at: 'blend') ~= 'intersect' ifTrue: [ ^ false ].
 self isSparseSampled ifFalse: [ ^ (descriptor at: 'additive') includes: nil ].
 points := (BVCLandformSampledEditField corners: (document at: 'contributionClip')) collect: [ :point | field gridPosition: point ].
 lower := (1 to: 3) collect: [ :i | (points collect: [ :p | p at: i ]) min floor ].
 upper := (1 to: 3) collect: [ :i | (points collect: [ :p | p at: i ]) max ceiling ].
 count := (1 to: 3) inject: 1 into: [ :n :i | n * ((upper at: i) - (lower at: i) + 1) ].
 self class require: count <= 3000000 code: 'SAMPLED_STENCIL_BUDGET'.
 (lower at: 1) to: (upper at: 1) do: [ :x |
  (lower at: 2) to: (upper at: 2) do: [ :y |
   (lower at: 3) to: (upper at: 3) do: [ :z |
    (field sampleGrid: { x. y. z } channel: 1) ifNil: [ ^ true ] ] ] ].
 ^ false
]

{ #category : 'accessing' }
BVCLandformBoundedEditPayload >> reference [
 ^ payloadReference deepCopy
]

{ #category : 'sampling' }
BVCLandformBoundedEditPayload >> sampleDenseAt: point channel: channel [
 | f grid low axes total index weight fraction value flat |
 f := field. grid := self denseGridPosition: point.
 low := grid collect: [ :n | n floor ].
 axes := (1 to: 3) select: [ :i | (grid at: i) ~= (low at: i) ].
 total := 0.0.
 0 to: (1 bitShift: axes size) - 1 do: [ :corner |
  index := low copy. weight := 1.0.
  axes withIndexDo: [ :axis :j |
   | bit |
   bit := (corner bitShift: j - axes size) bitAnd: 1.
   index at: axis put: (index at: axis) + bit.
   fraction := (grid at: axis) - (low at: axis).
   weight := weight * (bit = 1 ifTrue: [ fraction ] ifFalse: [ 1.0 - fraction ]) ].
  self class require: ((1 to: 3) allSatisfy: [ :i | (index at: i) >= 0 and: [ (index at: i) < ((f at: 'size') at: i) ] ]) code: 'SAMPLE_UNAVAILABLE'.
  flat := (index at: 1) + (((f at: 'size') at: 1) * ((index at: 2) + (((f at: 'size') at: 2) * (index at: 3)))) + 1.
  value := (f at: channel) at: flat.
  value ifNil: [ ^ nil ].
  total := total + (weight * value) ].
 ^ total
]

{ #category : 'validation' }
BVCLandformBoundedEditPayload >> validateDenseSupport [
 | f gridBounds points |
 f := document at: 'field'.
 self class require: ((((f at: 'rotationXYZW') collect: [ :n | n squared ]) sum - 1.0) abs < 1.0e-12) code: 'GRID_ROTATION'.
 gridBounds := Dictionary new at: 'minMeters' put: #(0 0 0); at: 'maxMeters' put: ((f at: 'size') collect: [ :n | n - 1 ]); yourself.
 points := (BVCLandformSampledEditField corners: gridBounds) collect: [ :g |
  | rotated |
  rotated := BVCLandformSampledEditField rotate: (g collect: [ :n | n * (f at: 'spacingMeters') ]) quaternion: (f at: 'rotationXYZW') inverse: false.
  (1 to: 3) collect: [ :i | ((f at: 'originMeters') at: i) + (rotated at: i) ] ].
 points do: [ :point | self class require: ((1 to: 3) allSatisfy: [ :i |
  (((document at: 'sampleFootprint') at: 'minMeters') at: i) - 1.0e-9 <= (point at: i)
   and: [ (point at: i) <= ((((document at: 'sampleFootprint') at: 'maxMeters') at: i) + 1.0e-9) ] ]) code: 'GRID_SAMPLE_FOOTPRINT' ].
 (BVCLandformSampledEditField corners: (document at: 'contributionClip')) do: [ :point |
  | grid |
  grid := self denseGridPosition: point.
  self class require: ((1 to: 3) allSatisfy: [ :i | (grid at: i) >= -1.0e-9 and: [ (grid at: i) <= (((f at: 'size') at: i) - 1 + 1.0e-9) ] ]) code: 'GRID_INTERPOLATION_HALO' ].
 self class require: (BVCLandformSampledEditField contains: (document at: 'readFootprint') bounds: (document at: 'sampleFootprint') halo: 0) code: 'PAYLOAD_READ_SUPPORT'
]

{ #category : 'validation' }
BVCLandformBoundedEditPayload >> validateDocumentFor: context [
 | common required representation expected procedure clip center radius shape |
 common := #('schema' 'recordId' 'context' 'numericProfileId' 'semantics' 'contributionClip' 'sampleFootprint' 'readFootprint' 'dirtyBounds' 'evaluationHaloMeters' 'capture' 'representation' 'channels' 'surfacePolicy').
 self class keys: document required: common optional: #('procedure' 'field').
 self class require: (document at: 'schema') = 'catalyst.bounded-edit-payload/draft' code: 'SCHEMA'.
 self class identifier: (document at: 'recordId'). self class context: (document at: 'context').
 self class require: (document at: 'context') = context code: 'PAYLOAD_CONTEXT'.
 self class require: (document at: 'semantics') = 'singleContribution' code: 'SCHEMA'.
 self class require: (#('catalyst.reference.float64/draft' 'catalyst.vpp-sampled.float32/draft') includes: (document at: 'numericProfileId')) code: 'SCHEMA'.
 representation := document at: 'representation'.
 self class require: (#('procedural' 'sampled') includes: representation) code: 'SCHEMA'.
 required := common, (representation = 'procedural' ifTrue: [ #('procedure') ] ifFalse: [ #('field') ]).
 self class keys: document required: required optional: #().
 self class require: (self isSparseSampled not or: [ self isProcedural not ]) code: 'SCHEMA'.
 #('contributionClip' 'sampleFootprint' 'readFootprint' 'dirtyBounds') do: [ :key |
  self class bounds: (document at: key) frame: (context at: 'bodyFrameId') ].
 self class finite: (document at: 'evaluationHaloMeters').
 self class require: (document at: 'evaluationHaloMeters') >= 0 code: 'SCHEMA'.
 self class capture: (document at: 'capture').
 self class require: (BVCLandformSampledEditField contains: (document at: 'readFootprint') bounds: (document at: 'contributionClip') halo: 0) code: 'PAYLOAD_READ_SUPPORT'.
 self class require: (BVCLandformSampledEditField contains: (document at: 'dirtyBounds') bounds: (document at: 'contributionClip') halo: (document at: 'evaluationHaloMeters')) code: 'PAYLOAD_DIRTY_HALO'.
 self isProcedural ifTrue: [
  self class require: (document at: 'surfacePolicy') = 'operatorDefined' code: 'SCHEMA'.
  procedure := document at: 'procedure'. self class operation: procedure.
  expected := (procedure at: 'operatorId') = 'catalyst.edit.sphere-remove/draft'
   ifTrue: [ #('geometry') ] ifFalse: [
    (procedure at: 'operatorId') = 'catalyst.edit.sphere-add/draft' ifTrue: [ #('geometry' 'surface') ] ifFalse: [ #('surface') ] ].
  self class require: (document at: 'channels') = expected code: 'PAYLOAD_CHANNELS'.
  center := procedure at: 'centerMeters'. radius := procedure at: 'radiusMeters'.
  shape := Dictionary new at: 'minMeters' put: (center collect: [ :n | n - radius ]); at: 'maxMeters' put: (center collect: [ :n | n + radius ]); yourself.
  self class require: (BVCLandformSampledEditField contains: (document at: 'contributionClip') bounds: shape halo: 0) code: 'PAYLOAD_SHAPE_CLIPPED'.
  self class require: (BVCLandformSampledEditField contains: (document at: 'sampleFootprint') bounds: (document at: 'contributionClip') halo: 0) code: 'PAYLOAD_SAMPLE_SUPPORT' ] ifFalse: [
  self class require: (document at: 'channels') = #('geometry') code: 'SCHEMA'.
  self class require: (document at: 'surfacePolicy') = 'preserve' code: 'SCHEMA'.
  self isSparseSampled ifTrue: [ self class nativeField: (document at: 'field') ] ifFalse: [ self class denseField: (document at: 'field') ].
  self class require: ((document at: 'capture') at: 'kind') = 'predecessorDependent' code: 'SAMPLED_CAPTURE_POLICY' ]
]

{ #category : 'validation' }
BVCLandformBoundedEditPayload >> validateNativeBinding [
 | descriptor domain mode lower upper sampleBox points |
 descriptor := document at: 'field'. domain := descriptor at: 'chunkDomain'.
 self class require: ((1 to: 3) allSatisfy: [ :i | ((descriptor at: 'originMeters') at: i) asFloat asIEEE64BitWord = (field originMeters at: i) asIEEE64BitWord ]) code: 'SAMPLED_TRANSFORM_BINDING'.
 self class require: ((1 to: 4) allSatisfy: [ :i | ((descriptor at: 'rotationXYZW') at: i) asFloat asIEEE64BitWord = (field rotationXYZW at: i) asIEEE64BitWord ]) code: 'SAMPLED_TRANSFORM_BINDING'.
 self class require: (descriptor at: 'spacingMeters') asFloat asIEEE64BitWord = field spacingMeters asIEEE64BitWord code: 'SAMPLED_TRANSFORM_BINDING'.
 self class require: ((domain at: 'minInclusive') = field chunkMinimum and: [ (domain at: 'maxExclusive') = field chunkMaximum ]) code: 'SAMPLED_DOMAIN_BINDING'.
 self class require: (descriptor at: 'chunkCount') = field chunkCount code: 'SAMPLED_COUNT_BINDING'.
 mode := (#('add' 'remove' 'intersect' 'override') indexOf: (descriptor at: 'blend')) - 1.
 self class require: (mode = field blendMode and: [ (descriptor at: 'applyOnVoid') = field applyOnVoid ]) code: 'SAMPLED_MODE_BINDING'.
 (BVCLandformSampledEditField corners: (document at: 'contributionClip')) do: [ :point |
  | grid |
  grid := field gridPosition: point.
  self class require: ((1 to: 3) allSatisfy: [ :i | (field chunkMinimum at: i) * 8 <= (grid at: i) and: [ (grid at: i) <= ((field chunkMaximum at: i) * 8) ] ]) code: 'SAMPLED_CLIP_DOMAIN' ].
 sampleBox := Dictionary new at: 'minMeters' put: (field chunkMinimum collect: [ :n | n * 8 ]); at: 'maxMeters' put: (field chunkMaximum collect: [ :n | n * 8 ]); yourself.
 points := (BVCLandformSampledEditField corners: sampleBox) collect: [ :point | field bodyPosition: point ].
 lower := (1 to: 3) collect: [ :i | (points collect: [ :p | p at: i ]) min ].
 upper := (1 to: 3) collect: [ :i | (points collect: [ :p | p at: i ]) max ].
 sampleBox at: 'minMeters' put: lower; at: 'maxMeters' put: upper.
 self class require: (BVCLandformSampledEditField contains: (document at: 'sampleFootprint') bounds: sampleBox halo: 0) code: 'SAMPLED_SAMPLE_FOOTPRINT'.
 self class require: (BVCLandformSampledEditField contains: (document at: 'readFootprint') bounds: (document at: 'sampleFootprint') halo: 0) code: 'PAYLOAD_READ_SUPPORT'
]

{ #category : 'validation' }
BVCLandformBoundedEditPayload >> validateRecovery: recovery evaluation: evaluation effective: effective [
 | policy start end expected |
 self class keys: recovery required: #('policyId') optional: #('start' 'end' 'channels' 'validityPolicy').
 policy := recovery at: 'policyId'.
 policy = 'catalyst.recovery.permanent/draft' ifTrue: [
  ^ self class keys: recovery required: #('policyId') optional: #() ].
 self class keys: recovery required: #('policyId' 'start' 'end' 'channels' 'validityPolicy') optional: #().
 self class require: (recovery at: 'channels') = #('geometry') code: 'SCHEMA'.
 self class require: (recovery at: 'validityPolicy') = 'finiteOnly' code: 'SCHEMA'.
 expected := self isSparseSampled ifTrue: [ 'catalyst.recovery.linear-sampled-field/draft' ] ifFalse: [ 'catalyst.recovery.linear-field/draft' ].
 self class require: policy = expected code: 'RECOVERY_PROFILE'.
 self class require: (self channels = #('geometry') and: [ self mayProduceVoid not ]) code: 'RECOVERY_CHANNEL_UNSUPPORTED'.
 start := recovery at: 'start'. end := recovery at: 'end'.
 self class time: start. self class time: end.
 { start. end. effective } do: [ :time |
  self class require: ((time at: 'domainId') = (evaluation at: 'domainId') and: [ (time at: 'epochId') = (evaluation at: 'epochId') ]) code: 'TIME_DOMAIN' ].
 self class require: ((effective at: 'tick') asInteger <= (start at: 'tick') asInteger and: [ (start at: 'tick') asInteger < (end at: 'tick') asInteger ]) code: 'RECOVERY_WINDOW'
]
