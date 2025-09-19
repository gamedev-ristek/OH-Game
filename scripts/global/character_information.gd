extends Node

var outfit_list:Array = [preload("uid://30yu5kl40dca"),preload("uid://c6vhir17mq3bj"),preload("uid://nnsvxw516ye0")]
var outfit_index:int = 0
var outfit:Texture2D = outfit_list[outfit_index]
var type_dict:Dictionary = {
	"male" : preload("uid://cujowj3sdjsde"),
	"female" : preload("uid://denfiqosvtsu5"),
	"panda" : preload("uid://cmfj1ojjrhob6")
}
var type:Texture2D = type_dict["male"]

signal outfit_updated
signal type_updated

func update_outfit(index:int) :
	var size:int = outfit_list.size()
	
	if (index >= size) :
		outfit_index = 0
	elif (index < 0) :
		outfit_index = size-1
	else :
		outfit_index = index
		
	outfit = outfit_list[outfit_index]
	outfit_updated.emit()

func update_type(input:String) :
	type = type_dict[input]
	type_updated.emit()
