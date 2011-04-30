function expand_section(sender_id, section_id, closed_sign, opened_sign) {
	text = sender_id.text();
	the_sign = text.substr(0, 1);
	if (the_sign == closed_sign) {
		text = text.replace(the_sign, opened_sign);
	} else if (the_sign == opened_sign) {
		text = text.replace(the_sign, closed_sign);
	}
	$(sender_id).html(text);
	$(sender_id).next(section_id).slideToggle(300);
}

function checkbox_expander(id)
{
	if ($("#" + id).attr("checked"))
	{
		// if (id.match("use_architectural")) {
			// $("#thin_film_coating").hide();
			// $("#dispersive_refraction").hide();
		// }
		if (id.match("show_advanced") || id.match("_use_")) {
			$("#" + id).nextAll(".basic").hide();
			$("#" + id).nextAll(".advanced").show();
		}
		$("#" + id).next(".collapse").show();
		// $("#" + id).next(".collapse").children("#focus_type").change();
	}
	else if ($("#" + id).attr("checked") == false)
	{
		// if (id.match("use_architectural")) {
			// $("#thin_film_coating").show();
			// $("#dispersive_refraction").show();
		// }
		if (id.match("show_advanced") || id.match("_use_")) {
			$("#" + id).nextAll(".basic").show();
			$("#" + id).nextAll(".advanced").hide();
		}
		$("#" + id).next(".collapse").hide();
	}
}

$(document).ready(
	function() {
	
		$("#settings_panel select, :text").change(
			function()
			{
				window.location = 'skp:param_generate@' + this.id+'='+this.value
			}
		);
		
		$(":checkbox").click(
			function()
			{
				window.location = 'skp:param_generate@' + this.id + '=' + $(this).attr('checked');
				checkbox_expander(this.id)
			}
		);
		
		$("#material_name").change(
			function() {
				window.location = 'skp:material_changed@' + this.value;
				$("#type").change();
			}
		);

		$("#type").change(
			function() {
				$(this).nextAll().hide();
				$(this).nextAll("." + this.value).show();
				window.location = 'skp:type_changed@' + this.value;
			}
		);
		
		$("#settings_panel p.header").click(
			function()
			{
				expand_section($(this), "div.collapse", "+", "-");
				$(this).next("div.collapse").find("select").change();
				// checkbox_expander("use_diffuse_texture");
				$("input:checkbox").each(function(index, element) { checkbox_expander(element.id) } );
				
				// node = $(this).next("div.collapse").children("#accelerator_type").attr("value");
				// $(this).next("div.collapse").children("#accelerator_type").siblings("#" + node).show();
			}
		);
		
		// $("#settings_panel #type").change(
			// function()
			// {
				// $(this).nextAll().hide();
				// $(this).nextAll("." + this.value).show();
			// }
		// );
		
		$('select[id$="_imagemap_filtertype"]').change(
			function()
			{
				$(this).nextAll().hide();
				$(this).nextAll("." + this.value).show();
			}
		);
		
		$('select[id$="_texturetype"]').change(
			function()
			{
				$(this).nextAll().hide();
				$(this).nextAll("." + this.value).show();
			}
		);
		
		$('input[id$="_browse"]').click(
			function()
			{
				id = this.id;
				index = id.lastIndexOf("_browse");
				text = id.substring(0, index);
				window.location = 'skp:open_dialog@' + text;
			}
		)
		
		$('input[id$="_browse_map"]').click(
			function()
			{
				id = this.id;
				index = id.lastIndexOf("_browse_map");
				text = id.substring(0, index);
				window.location = 'skp:texture_editor@' + text;
			}
		)
		
		$("#get_diffuse_color").click(
			function()
			{
				window.location = 'skp:get_diffuse_color'
			}
		);
		
		$("#save_to_model").click(
			function()
			{
				window.location = 'skp:save_to_model';
			}
		);
		
		$("#reset").click(
			function()
			{
				window.location = 'skp:reset_to_default';
			}
		);
		
		$('input[id="update_changes"]').click(
			function()
			{
				window.location = 'skp:update_changes';
			}
		)
		
		$('input[id="cancel_changes"]').click(
			function()
			{
				window.location = 'skp:cancel_changes';
			}
		)
		
	}		
);


// //TODO add spinner plugin for number input field 
// function checkbox_expander(id)
// {
	// if ($("#" + id).attr("checked"))
	// {
		// if (id.match("show_advanced") || id.match("_use_")) {
			// $("#" + id).nextAll(".basic").hide();
			// $("#" + id).nextAll(".advanced").show();
		// }
		// $("#" + id).next(".collapse").show();
		// $("#" + id).next(".collapse").children("#focus_type").change();
	// }
	// else if ($("#" + id).attr("checked") == false)
	// {
		// if (id.match("show_advanced") || id.match("_use_")) {
			// $("#" + id).nextAll(".basic").show();
			// $("#" + id).nextAll(".advanced").hide();
		// }
		// $("#" + id).next(".collapse").hide();
	// }
// }

// $(document).ready(
	// function()
	// {
		// $(".collapse").hide();
		// $(".collapse2").hide();
		// $(".advanced").hide();
		// window.location = 'skp:set_material_list';
	
		// $("#settings_panel select, :text").change(
			// function()
			// {
				// window.location = 'skp:param_generate@' + this.id+'='+this.value+'|'+"material_name="+$("#material_name").attr("value");
			// }
		// );
		
		// $("#settings_panel #type").change(
			// function()
			// {
				// $(this).nextAll().hide();
				// $(this).nextAll("." + this.value).show();
			// }
		// );
		
		// $(":checkbox").click(
			// function()
			// {
				// window.location = 'skp:param_generate@' + this.id + '=' + $(this).attr('checked');
				// checkbox_expander(this.id)
			// }
		// );
		
		// $("#settings_panel input[name=use_plain_color]:radio").click(
			// function()
			// {
				// window.location = 'skp:param_generate@' + this.name + '=' + this.value;
			// }
		// );
		
		// $("#settings_panel p.header").click(
			// function()
			// {
				// node = $(this).next("div.collapse").children("#accelerator_type").attr("value");
				// $(this).next("div.collapse").children("#accelerator_type").siblings("#" + node).show();
				// node = $(this).next("div.collapse").children("#sintegrator_type").attr("value");
				// $(this).next("div.collapse").children("#sintegrator_type").siblings("#" + node).show();
				// node = $(this).next("div.collapse").children("#camera_type").change();
				// node = $(this).next("div.collapse").children("#environment_light_type").change();
				// node = $(this).next("div.collapse").children("#sampler_type").change();
				// node = $(this).next("div.collapse").children("#pixelfilter_type").change();
				// node = $(this).next("div.collapse").children("#fleximage_tonemapkernel").change();
				// node = $(this).next("div.collapse").find("#sintegrator_path_rrstrategy").change();
				// node = $(this).next("div.collapse").find("#sintegrator_exphoton_rrstrategy").change();
				// node = $(this).next("div.collapse").find("#fleximage_write_exr_compressiontype").change();
				// node = $(this).next("div.collapse").find("#fleximage_write_exr_zbuf_normalizationtype").change();
				// node = $(this).next("div.collapse").find("#fleximage_linear_camera_type").change();
				
				// //TODO: expand all checkbox
				// checkbox_expander("fleximage_write_exr")
				// checkbox_expander("fleximage_write_png")
				// checkbox_expander("fleximage_write_tga")
				// checkbox_expander("fleximage_use_preset")
				
				// var name = $(this).text();
				// var the_sign = name.substr(0, 1);
				// if (the_sign == "+") {
					// name = name.replace(the_sign, "-");
				// } else if (the_sign == "-") {
					// name = name.replace(the_sign, "+");
				// }
				// $(this).html(name);
				// $(this).next("div.collapse").slideToggle(300);
				// // node = $(this).next("div.collapse").children("#environment_light_type").attr("value");
				// // $(this).next("div.collapse").children("#environment_light_type").siblings("#" + node).show();
			// }
		// );
				
		// $("#settings_panel p.header2").click(
			// function()
			// {
				// node = $(this).next("div.collapse2").children("#accelerator_type").attr("value");
				// $(this).next("div.collapse2").children("#accelerator_type").siblings("#" + node).show();
				// node = $(this).next("div.collapse2").children("#sintegrator_type").attr("value");
				// $(this).next("div.collapse2").children("#sintegrator_type").siblings("#" + node).show();
// //				node = $(this).next("div.collapse2").children("#camera_type").change();
				// $(this).next("div.collapse2").slideToggle(300);
				// // node = $(this).next("div.collapse").children("#environment_light_type").attr("value");
				// // $(this).next("div.collapse").children("#environment_light_type").siblings("#" + node).show();
			// }
		// );
				
		// // $("#settings_panel #sintegrator_type").change(
			// // function()
			// // {
				// // //alert("#"+this.value);
				// // nodes = $(this).nextAll().hide();
				// // nodes = $(this).nextAll("#" + this.value).show();
			// // }
		// // );
		
		// $("#save_to_model").click(
			// function()
			// {
				// window.location = 'skp:save_to_model';
			// }
		// );
		
		// $("#reset").click(
			// function()
			// {
				// window.location = 'skp:reset_to_default';
			// }
		// );
		
	// }
// );
