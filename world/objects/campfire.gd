class_name Campfire
extends Node2D

enum CampfireMode {
	Ignite,
	AlwaysIgnited,
	NeverIgnited,
}

@export var anim: AnimationPlayer
@export var mode: CampfireMode
