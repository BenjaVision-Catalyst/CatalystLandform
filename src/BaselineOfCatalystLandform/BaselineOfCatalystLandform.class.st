"
Metacello entry point for the independent Catalyst Landform runtime-service domain objects. Core and Examples are separate load groups; transport remains owned by Catalyst Connect.
"
Class {
	#name : 'BaselineOfCatalystLandform',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfCatalystLandform',
	#package : 'BaselineOfCatalystLandform'
}

{ #category : 'baseline' }
BaselineOfCatalystLandform >> baseline: spec [
 <baseline>
 spec for: #common do: [
  spec package: 'BVC-Landform-Core' with: [ spec requires: #('NeoJSON') ].
  spec package: 'BVC-Landform-Examples' with: [ spec requires: #('BVC-Landform-Core') ].
  spec group: 'Core' with: #('BVC-Landform-Core').
  spec group: 'Examples' with: #('BVC-Landform-Examples').
  spec group: 'default' with: #('Core') ].
 spec for: #pharo do: [
  spec baseline: 'NeoJSON' with: [
   spec repository: 'github://svenvc/NeoJSON:master/repository'; loads: #('core') ] ].
 spec for: #gemstone do: [
  spec baseline: 'NeoJSON' with: [
   spec repository: 'github://GsDevKit/NeoJSON:gs_master/filetree'; loads: #('Core') ] ]
]
