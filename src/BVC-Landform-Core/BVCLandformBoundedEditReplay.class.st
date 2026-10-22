"
An immutable accepted bounded-edit fold pinned to context and evaluation time. Resolves and validates payloads once; replays procedural, dense and Sampled entries in order. The owning formation evaluator supplies a pinned predecessor. Commit transactions, spatial indexing and activation coordination remain outside this kernel.
"
Class {
	#name : 'BVCLandformBoundedEditReplay',
	#superclass : 'Object',
	#instVars : [
		'context',
		'evaluation',
		'edits',
		'payloads'
	],
	#category : 'BVC-Landform-Core',
	#package : 'BVC-Landform-Core'
}

{ #category : 'instance creation' }
BVCLandformBoundedEditReplay class >> recipe: recipe payloadResolver: resolver enabledProfiles: enabledProfiles [
 ^ self new initializeForRecipe: recipe payloadResolver: resolver enabledProfiles: enabledProfiles
]

{ #category : 'instance creation' }
BVCLandformBoundedEditReplay class >> recipe: recipe resources: resources enabledProfiles: enabledProfiles [
 ^ self new initializeForRecipe: recipe resources: resources enabledProfiles: enabledProfiles
]

{ #category : 'accessing' }
BVCLandformBoundedEditReplay >> context [
 ^ context deepCopy
]

{ #category : 'accessing' }
BVCLandformBoundedEditReplay >> editCount [
 ^ edits size
]

{ #category : 'accessing' }
BVCLandformBoundedEditReplay >> evaluation [
 ^ evaluation deepCopy
]

{ #category : 'initialization' }
BVCLandformBoundedEditReplay >> initializeForRecipe: recipe payloadResolver: resolver enabledProfiles: enabledProfiles [
 | profile editPlan available used descriptor entry key payload previousId previousCounter previousTie ids counter tie op effective shape radius center |
 BVCLandformBoundedEditPayload keys: recipe required: #('schema' 'recipeId' 'context' 'revision' 'sceneToken' 'evaluation' 'radialGuides' 'geology' 'editPlan' 'editPayloadRefs' 'foundation' 'profile' 'maxEnvelopeRadiusMeters') optional: #().
 self require: (recipe at: 'schema') = 'catalyst.terrain-recipe/draft' code: 'SCHEMA'.
 context := (recipe at: 'context') deepCopy. evaluation := (recipe at: 'evaluation') deepCopy.
 BVCLandformBoundedEditPayload context: context. BVCLandformBoundedEditPayload time: evaluation.
 profile := recipe at: 'profile'.
 self require: (#('catalyst.reference.float64/draft' 'catalyst.composition.meter64-cell32/draft') includes: (profile at: 'numericProfileId')) code: 'SCHEMA'.
 self require: (profile at: 'lowering') = 'ownedComposite' code: 'SCHEMA'.
 self require: (enabledProfiles includes: (profile at: 'numericProfileId')) code: 'PROFILE_NOT_NEGOTIATED'.
 editPlan := recipe at: 'editPlan'.
 BVCLandformBoundedEditPayload keys: editPlan required: #('schema' 'context' 'editPlanId' 'revision' 'baseFormationRevision' 'baselineSceneToken' 'edits') optional: #().
 self require: (editPlan at: 'schema') = 'catalyst.bounded-edit-plan/draft' code: 'SCHEMA'.
 { editPlan. recipe at: 'radialGuides'. recipe at: 'geology' } do: [ :part | self require: (part at: 'context') = context code: 'CONTEXT_MISMATCH' ].
 self require: (editPlan at: 'baseFormationRevision') = ((recipe at: 'geology') at: 'revision') code: 'BASE_FORMATION_MISMATCH'.
 payloads := Dictionary new. used := Set new.
 (recipe at: 'editPayloadRefs') do: [ :ref |
  BVCLandformBoundedEditPayload reference: ref binary: false.
  key := ref at: 'payloadId'.
  self require: (payloads includesKey: key) not code: 'DUPLICATE_PAYLOAD'.
  payload := resolver value: ref deepCopy value: context deepCopy.
  self require: (payload isKindOf: BVCLandformBoundedEditPayload) code: 'PAYLOAD_MISSING'.
  self require: payload reference = ref code: 'PAYLOAD_DESCRIPTOR'.
  self require: (payload document at: 'context') = context code: 'PAYLOAD_CONTEXT'.
  self require: (enabledProfiles includes: (payload document at: 'numericProfileId')) code: 'PROFILE_NOT_NEGOTIATED'.
  self require: (payload isSparseSampled not or: [ (profile at: 'numericProfileId') = 'catalyst.composition.meter64-cell32/draft' ]) code: 'COMPOSITION_PROFILE'.
  self require: payload mayProduceVoid not code: 'FINITE_PROFILE_REQUIRED'.
  payloads at: key put: payload ].
 edits := (editPlan at: 'edits') deepCopy.
 self require: ((edits isKindOf: Array) and: [ edits size <= 10000 ]) code: 'SCHEMA'.
 previousId := nil. previousCounter := nil. previousTie := nil. ids := Set new.
 edits do: [ :edit |
  BVCLandformBoundedEditPayload keys: edit required: #('editId' 'orderKey' 'afterEditId' 'effectiveTime' 'attachment' 'operation' 'recovery' 'contributionClip' 'readFootprint' 'dirtyBounds' 'evaluationHaloMeters' 'hydrologyImpact') optional: #().
  BVCLandformBoundedEditPayload identifier: (edit at: 'editId').
  self require: (ids includes: (edit at: 'editId')) not code: 'DUPLICATE_EDIT'. ids add: (edit at: 'editId').
  self require: (edit at: 'attachment') = 'bodyFixed' code: 'SCHEMA'.
  self require: (#('none' 'reconcile') includes: (edit at: 'hydrologyImpact')) code: 'SCHEMA'.
  BVCLandformBoundedEditPayload keys: (edit at: 'orderKey') required: #('counter' 'tieBreaker') optional: #().
  counter := BVCLandformBoundedEditPayload uint64: ((edit at: 'orderKey') at: 'counter').
  tie := (edit at: 'orderKey') at: 'tieBreaker'. BVCLandformBoundedEditPayload identifier: tie.
  previousCounter ifNotNil: [ self require: (counter > previousCounter or: [ counter = previousCounter and: [ previousTie < tie ] ]) code: 'EDIT_ORDER' ].
  self require: (edit at: 'afterEditId') = previousId code: 'EDIT_PREDECESSOR'.
  previousId := edit at: 'editId'. previousCounter := counter. previousTie := tie.
  effective := edit at: 'effectiveTime'. BVCLandformBoundedEditPayload time: effective.
  self require: ((effective at: 'domainId') = (evaluation at: 'domainId') and: [ (effective at: 'epochId') = (evaluation at: 'epochId') ]) code: 'TIME_DOMAIN'.
  #('contributionClip' 'readFootprint' 'dirtyBounds') do: [ :name | BVCLandformBoundedEditPayload bounds: (edit at: name) frame: (context at: 'bodyFrameId') ].
  BVCLandformBoundedEditPayload finite: (edit at: 'evaluationHaloMeters').
  self require: (edit at: 'evaluationHaloMeters') >= 0 code: 'SCHEMA'.
  self require: (BVCLandformSampledEditField contains: (edit at: 'readFootprint') bounds: (edit at: 'contributionClip') halo: 0) code: 'READ_FOOTPRINT'.
  self require: (BVCLandformSampledEditField contains: (edit at: 'dirtyBounds') bounds: (edit at: 'contributionClip') halo: (edit at: 'evaluationHaloMeters')) code: 'DIRTY_HALO'.
  op := edit at: 'operation'.
  (op at: 'operatorId') = 'catalyst.edit.bounded-payload/draft'
   ifTrue: [
    BVCLandformBoundedEditPayload keys: op required: #('operatorId' 'payloadId') optional: #().
    payload := payloads at: (op at: 'payloadId') ifAbsent: [ BVCLandformBoundedEditError signalCode: 'PAYLOAD_MISSING' ].
    descriptor := payload document.
    #('contributionClip' 'readFootprint' 'dirtyBounds' 'evaluationHaloMeters') do: [ :name | self require: (edit at: name) = (descriptor at: name) code: 'PAYLOAD_EDIT_SUPPORT_MISMATCH' ].
    payload validateRecovery: (edit at: 'recovery') evaluation: evaluation effective: effective ]
   ifFalse: [
    BVCLandformBoundedEditPayload operation: op.
    radius := op at: 'radiusMeters'. center := op at: 'centerMeters'.
    shape := Dictionary new at: 'minMeters' put: (center collect: [ :n | n - radius ]); at: 'maxMeters' put: (center collect: [ :n | n + radius ]); yourself.
    self require: (BVCLandformSampledEditField contains: (edit at: 'contributionClip') bounds: shape halo: 0) code: 'EDIT_SHAPE_CLIPPED'.
    self validateDirectRecovery: (edit at: 'recovery') operation: op effective: effective ] ].
 ^ self
]

{ #category : 'initialization' }
BVCLandformBoundedEditReplay >> initializeForRecipe: recipe resources: resources enabledProfiles: enabledProfiles [
 | available key |
 self require: ((resources isKindOf: Array) and: [ resources size <= 10000 ]) code: 'SCHEMA'.
 available := Dictionary new.
 resources do: [ :resource |
  BVCLandformBoundedEditPayload keys: resource required: #('ref' 'document' 'encodedUtf8Base64') optional: #('dependencies').
  BVCLandformBoundedEditPayload reference: (resource at: 'ref') binary: false.
  key := (resource at: 'ref') at: 'payloadId'.
  self require: (available includesKey: key) not code: 'DUPLICATE_PAYLOAD'.
  available at: key put: resource ].
 ^ self initializeForRecipe: recipe payloadResolver: [ :ref :bodyContext |
  | resource |
  resource := available at: (ref at: 'payloadId') ifAbsent: [ BVCLandformBoundedEditError signalCode: 'PAYLOAD_MISSING' ].
  self require: (resource at: 'ref') = ref code: 'PAYLOAD_DESCRIPTOR'.
  BVCLandformBoundedEditPayload fromResource: resource context: bodyContext ] enabledProfiles: enabledProfiles
]

{ #category : 'replay' }
BVCLandformBoundedEditReplay >> replayAt: point distance: distance material: material [
 | result tick weight recovery start end operation full |
 BVCLandformBoundedEditPayload vector: point size: 3.
 BVCLandformBoundedEditPayload finite: distance.
 result := { distance. material }. tick := (evaluation at: 'tick') asInteger.
 edits do: [ :edit |
  (tick >= ((edit at: 'effectiveTime') at: 'tick') asInteger and: [ BVCLandformSampledEditField inside: (edit at: 'contributionClip') point: point ]) ifTrue: [
   recovery := edit at: 'recovery'. weight := 1.0.
   (recovery includesKey: 'start') ifTrue: [
    start := (recovery at: 'start') at: 'tick'. end := (recovery at: 'end') at: 'tick'.
    weight := (((end asInteger - tick) / (end asInteger - start asInteger)) asFloat max: 0.0) min: 1.0 ].
   weight = 0 ifFalse: [
    operation := edit at: 'operation'.
    result := (operation at: 'operatorId') = 'catalyst.edit.bounded-payload/draft'
     ifTrue: [ (payloads at: (operation at: 'payloadId')) applyAt: point distance: result first material: result second weight: weight ]
     ifFalse: [
      full := BVCLandformBoundedEditPayload applyProcedure: operation at: point distance: result first material: result second weight: 1.0.
      weight = 1.0 ifFalse: [ full at: 1 put: ((1.0 - weight) * result first) + (weight * full first) ].
      full ] ] ] ].
 ^ result
]

{ #category : 'validation' }
BVCLandformBoundedEditReplay >> require: condition code: code [
 ^ BVCLandformSampledEditField require: condition code: code
]

{ #category : 'replay' }
BVCLandformBoundedEditReplay >> sample: points baseline: baselineSampler [
 "The caller owns formation evaluation and must supply a pinned predecessor."
 | inputs |
 self require: ((points isKindOf: Array) and: [ points size <= 10000 ]) code: 'QUERY_BUDGET'.
 points do: [ :point | BVCLandformBoundedEditPayload vector: point size: 3 ].
 inputs := points collect: [ :point | baselineSampler value: point ].
 ^ points with: inputs collect: [ :point :base |
  | result |
  result := self replayAt: point distance: (base at: 'distanceMeters') material: (base at: 'materialId').
  base copy at: 'distanceMeters' put: result first; at: 'materialId' put: result second; yourself ]
]

{ #category : 'validation' }
BVCLandformBoundedEditReplay >> validateDirectRecovery: recovery operation: operation effective: effective [
 | start end |
 BVCLandformBoundedEditPayload keys: recovery required: #('policyId') optional: #('start' 'end' 'channels' 'validityPolicy').
 (recovery at: 'policyId') = 'catalyst.recovery.permanent/draft' ifTrue: [
  ^ BVCLandformBoundedEditPayload keys: recovery required: #('policyId') optional: #() ].
 BVCLandformBoundedEditPayload keys: recovery required: #('policyId' 'start' 'end' 'channels' 'validityPolicy') optional: #().
 self require: (recovery at: 'policyId') = 'catalyst.recovery.linear-field/draft' code: 'RECOVERY_PROFILE'.
 self require: ((recovery at: 'channels') = #('geometry') and: [ (recovery at: 'validityPolicy') = 'finiteOnly' ]) code: 'SCHEMA'.
 self require: (operation at: 'operatorId') = 'catalyst.edit.sphere-remove/draft' code: 'RECOVERY_CHANNEL_UNSUPPORTED'.
 start := recovery at: 'start'. end := recovery at: 'end'.
 BVCLandformBoundedEditPayload time: start. BVCLandformBoundedEditPayload time: end.
 { start. end. effective } do: [ :time |
  self require: ((time at: 'domainId') = (evaluation at: 'domainId') and: [ (time at: 'epochId') = (evaluation at: 'epochId') ]) code: 'TIME_DOMAIN' ].
 self require: ((effective at: 'tick') asInteger <= (start at: 'tick') asInteger and: [ (start at: 'tick') asInteger < (end at: 'tick') asInteger ]) code: 'RECOVERY_WINDOW'
]
