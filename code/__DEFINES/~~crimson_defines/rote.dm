#define MAGICK_BASE_DIFFICULTY 6

#define MAGICK_DATA_ACTIVATE			(1<<0)
#define MAGICK_DATA_BOOL  				(1<<1)
#define MAGICK_DATA_NUMBER  			(1<<2)
#define MAGICK_DATA_STRING  			(1<<3)
#define MAGICK_DATA_TURF    			(1<<4)
#define MAGICK_DATA_OBJ     			(1<<5)
#define MAGICK_DATA_MOB     			(1<<6)
#define MAGICK_DATA_ANY     			(MAGICK_DATA_TURF | MAGICK_DATA_OBJ | MAGICK_DATA_MOB)
#define MAGICK_DATA_COUNT_ONE			(1<<21)
#define MAGICK_DATA_COUNT_LIST			(1<<22)
#define MAGICK_DATA_COUNT_ANY   		(1<<23)

#define MAGICK_DATA_LINK_VALID(out_flags, in_flags) (!((out_flags) & ~(in_flags)))

#define MAGICK_VULGAR_FIRE 				(1<<0)
#define MAGICK_VULGAR_EXPLOSION 		(1<<1)
#define MAGICK_VULGAR_ELECTRIC			(1<<2)
#define MAGICK_VULGAR_KINETIC			(1<<3)
#define MAGICK_VULGAR_GAS 				(1<<4)
#define MAGICK_VULGAR_ACID 				(1<<5)
#define MAGICK_VULGAR_BASIC_BIO 		(1<<6)
#define MAGICK_VULGAR_COMPLEX_BIO 		(1<<7)

#define MAGICK_TAG_DATA					(1<<0) // For effects that do nothing besides data processing
#define MAGICK_TAG_UTILITY				(1<<1)
#define MAGICK_TAG_DAMAGE				(1<<2)
#define MAGICK_TAG_BUFF					(1<<3)
#define MAGICK_TAG_DEBUFF				(1<<4)

/proc/init_magick_effect_static_data()
	var/list/data = list()
	var/list/effects_list = list()

	for(var/effect_type as anything in subtypesof(/datum/magick_effect/))
		var/datum/magick_effect/effect = new effect_type()

		var/list/effect_data = list(
			"name" = effect.name,
			"desc" = effect.desc,
			"type" = "[effect_type]",
			"tags" = effect.tags,
			"looks_like" = effect.looks_like,
			"explains" = effect.explains,
			"quintessence" = effect.quintessence,
			"min_successes" = effect.min_successes,
			"complexity" = effect.complexity,
			"spheres" = effect.spheres,
		)

		// inputs
		var/list/inputs_list = list()
		var/alist/inputs = effect.inputs
		if(inputs)
			for(var/input_key as anything in inputs)
				inputs_list[input_key] = inputs[input_key]
		effect_data["inputs"] = inputs_list

		// outputs
		var/list/outputs_list = list()
		var/alist/outputs = effect.outputs
		if(outputs)
			for(var/output_key as anything in outputs)
				outputs_list[output_key] = outputs[output_key]
		effect_data["outputs"] = outputs_list

		effects_list += list(effect_data)
		qdel(effect)

	data["effects"] = effects_list
	return data

GLOBAL_LIST_INIT(magick_effect_static_data, init_magick_effect_static_data())
