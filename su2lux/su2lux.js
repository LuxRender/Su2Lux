<!--TODO add spinner plugin for number input field -->
function checkbox_expander(id)
{
	if ($("#" + id).attr("checked"))
	{
		if (id.match("show_advanced") || id.match("_use_")) {
			$("#" + id).nextAll(".basic").hide();
			$("#" + id).nextAll(".advanced").show();
		}
		$("#" + id).nextAll(".collapse").show();
		$("#" + id).nextAll(".collapse").children("#focus_type").change();
	}
	else if ($("#" + id).attr("checked") == false)
	{
		if (id.match("show_advanced") || id.match("_use_")) {
			$("#" + id).nextAll(".basic").show();
			$("#" + id).nextAll(".advanced").hide();
		}
		$("#" + id).nextAll(".collapse").hide();
	}
}

function update_settings_dropdown(presetname){
    //alert (presetname);
    var preset_exists = false;
    $('#preset option').each(
        function(){
            if (this.value == presetname  || this.text == presetname) {
                preset_exists = true;
            }
        }
    )
    if (preset_exists==true){
        //alert ("preset existed already")
        $("#preset").val(presetname);
    }else{
        //alert ("new preset loaded")
        $("#preset").append($('<option></option>').val(presetname).html(presetname));
        $("#preset").val(presetname); // make current
    }
    window.location = 'skp:display_loaded_presets@'   // refresh view
}

function add_to_dropdown(simplepreset){
    //alert ("add_to_dropdown running");
    $("#preset").append($('<option></option>').val(simplepreset).html(simplepreset));
    if (simplepreset == 'Final interior - MLT+Bidirectional path tracing (recommended)'){
        // set dropdown to recommended setting
        $("#preset").val(simplepreset);
        window.location = 'skp:load_settings@' + $("#preset option:selected").text()
    }
}

function update_subfield(field_class)
{
    //alert(field_class)
    $("#"+field_class).nextAll("."+field_class).hide();
    id_option_string = "#" + field_class + " option:selected"
    idname = $(id_option_string).text()
    $("#"+field_class).nextAll("#"+idname).show();
}



$(document).ready(
	function()
	{
        // alert ("settings DOM ready")
        window.location = 'skp:load_preset_files@'
        
		$(".collapse").hide();
		$(".collapse2").hide();
		$(".advanced").hide();
        $("#camera").next(".collapse").show(); // shows camera settings by default
        $("#imageresolution").next(".collapse").show();
        $("#system").next(".collapse").show();
                  
        // todo 2014: load settings
                  
                  
                  
        $("#save_settings_file").click(
            function()
            {
                window.location = 'skp:export_settings@' + this.value
            }
        )
                  
        $("#overwrite_settings_file").click(
            function()
            {
                window.location = 'skp:overwrite_settings@' + $("#preset").val()
            }
        )

        $("#load_settings_file").click(
            function()
            {
                window.location = 'skp:load_settings@' + false
            }
        )
                  
        $("#delete_settings_file").click(
            function()
            {
                window.location = 'skp:delete_settings@' + $("#preset option:selected").text()
            }
        )
	
		$("#settings_panel select, :text").change(
			function()
			{
				window.location = 'skp:param_generate@' + this.id+'='+this.value;
			}
		);
		
		$("#settings_panel #camera_type").change(
			function()
			{
				$(this).nextAll().hide();
				$(this).nextAll("." + this.value).show();
				window.location = 'skp:camera_change@' + this.value
			}
		);
		
		$("#settings_panel #focus_type").change(
			function()
			{
				$(this).nextAll("div").hide();
                $(this).nextAll("span").hide();
                $(this).nextAll("." + this.value).show();
			}
		);
		
		$("#settings_panel #environment_light_type").change(
			function()
			{
				$(this).nextAll().hide();
				$(this).nextAll("." + this.value).show();
			}
		);
                  
                  
                  
 		$("#settings_panel #aspectratio_type").change(
			function()
			{
                if (this.value=="aspectratio_sketchup_view"){
                    $("#aspectratio_sketchup_view").show();
                    $("#aspectratio_free").hide();
                    $("#aspectratio_custom").hide();
                    $("#aspectratio_fixed").hide();
                    if ($("#aspectratio_skp_res_type").val()=="aspectratio_skp_view"){
                      $("#aspectratio_resolution_interface").hide();
                      window.location = 'skp:remove_frame@' + this.value
                    }else{
                      // start function that updates y resolution based on x resolution (1)
                      window.location = 'skp:resolution_update_skp@' + this.value
                    }
                }else if (this.value=="aspectratio_free"){
                    $("#aspectratio_sketchup_view").hide();
                    $("#aspectratio_free").show();
                    $("#aspectratio_custom").hide();
                    $("#aspectratio_fixed").hide();
                    $("#aspectratio_resolution_interface").show();
                    window.location = 'skp:resolution_update_free@' + this.value;
                }else if (this.value=="aspectratio_custom"){
                    $("#aspectratio_sketchup_view").hide();
                    $("#aspectratio_free").hide();
                    $("#aspectratio_custom").show();
                    $("#aspectratio_fixed").hide();
                    $("#aspectratio_resolution_interface").show();
                    // start function that updates resolutions based on custom aspect ratio
                    window.location = 'skp:resolution_update_custom@' + this.value
                }else { // fixed ratio
                    $("#aspectratio_sketchup_view").hide();
                    $("#aspectratio_free").hide();
                    $("#aspectratio_custom").hide();
                    $("#aspectratio_fixed").show();
                    $("#aspectratio_resolution_interface").show();
                    // start function that updates resolutions based on aspect ratio
                    window.location = 'skp:resolution_update_fixed@' + this.value
                }
			}
		);
                  
  		$("#settings_panel #aspectratio_skp_res_type").change(
			function()
			{
                if (this.value=="aspectratio_skp_view"){
                    $("#aspectratio_resolution_interface").hide();
                }else { // custom ratio
                    $("#aspectratio_resolution_interface").show();
                    window.location = 'skp:resolution_update_skp@' + this.value
                }
			}
		);
        
        $("#settings_panel #aspectratio_fixed_orientation").change(
           function(){
                //alert(this.value)
                window.location = 'skp:swap_portrait_landscape@' + this.value               
           }
        );
                  
                  
        $("#settings_panel #aspectratio_flip").click(
           function(){
                //alert(this.value)
                window.location = 'skp:flip_aspect_ratio@' + this.value               
           }
        );
                  
                  
		$("#settings_panel #sintegrator_path_rrstrategy").change(
			function()
			{
				$(this).nextAll("div").hide();
				$(this).nextAll("span").hide();
				$(this).nextAll("." + this.value).show();
			}
		);
		
		$("#settings_panel #sintegrator_exphoton_rrstrategy").change(
			function()
			{
				$(this).nextAll("div").hide();
				$(this).nextAll("span").hide();
				$(this).nextAll("." + this.value).show();
			}
		);
		
		$("#settings_panel #sampler_type").change(
			function()
			{
				$(this).nextAll(".sampler_type").hide();
				$(this).nextAll("#" + this.value).show();
			}
		);
		
		$("#settings_panel #pixelfilter_type").change(
			function()
			{
				$(this).nextAll().hide();
				$(this).nextAll("#" + this.value).show();
			}
		);
		
		$("#settings_panel #fleximage_tonemapkernel").change(
			function()
			{
				$(this).nextAll("div").hide();
				$(this).nextAll("." + this.value).show();
			}
		);
		
		$("#settings_panel #fleximage_linear_camera_type").change(
			function()
			{
				$(this).nextAll("div").hide();
				$(this).nextAll("span").hide();
				$(this).nextAll("." + this.value).show();
			}
		);
		
		$("#presets select").change(
			function()
			{
				//alert("loading settings for preset");
				//window.location = 'skp:preset@' + this.value;
                window.location = 'skp:load_settings@' + $("#preset option:selected").text()
			}
		);

		$(":checkbox").click(
			function()
            {   // note: changing the order of the following methods will cause synchronity issues on OS X
                checkbox_expander(this.id);
                window.location = 'skp:param_generate@' + this.id + '=' + $(this).attr('checked');
			}
		);
		
		$("#settings_panel input[name=use_plain_color]:radio").click(
			function()
			{
				window.location = 'skp:param_generate@' + this.name + '=' + this.value;
			}
		);
		
		$("#settings_panel p.header").click(
			function()
			{
				node = $(this).next("div.collapse").children("#accelerator_type").attr("value");
				$(this).next("div.collapse").children("#accelerator_type").siblings("#" + node).show();
				node = $(this).next("div.collapse").children("#sintegrator_type").attr("value");
				$(this).next("div.collapse").children("#sintegrator_type").siblings("#" + node).show();
				node = $(this).next("div.collapse").children("#camera_type").change();
				node = $(this).next("div.collapse").children("#environment_light_type").change();
				node = $(this).next("div.collapse").children("#sampler_type").change();
				node = $(this).next("div.collapse").children("#pixelfilter_type").change();
				node = $(this).next("div.collapse").children("#fleximage_tonemapkernel").change();
				node = $(this).next("div.collapse").find("#sintegrator_path_rrstrategy").change();
				node = $(this).next("div.collapse").find("#sintegrator_exphoton_rrstrategy").change();
				node = $(this).next("div.collapse").find("#fleximage_write_exr_compressiontype").change();
				node = $(this).next("div.collapse").find("#fleximage_write_exr_zbuf_normalizationtype").change();
				node = $(this).next("div.collapse").find("#fleximage_linear_camera_type").change();
				
				//TODO: expand all checkbox
				// checkbox_expander("fleximage_write_exr")
				// checkbox_expander("fleximage_write_png")
				// checkbox_expander("fleximage_write_tga")
				// checkbox_expander("fleximage_use_preset")
				$("input:checkbox").each(function(index, element) { checkbox_expander(element.id) } );
				$(this).next("div.collapse").slideToggle(300);
				// node = $(this).next("div.collapse").children("#environment_light_type").attr("value");
				// $(this).next("div.collapse").children("#environment_light_type").siblings("#" + node).show();
			}
		);
				
		$("#settings_panel p.header2").click(
			function()
			{
				node = $(this).next("div.collapse2").children("#accelerator_type").attr("value");
				$(this).next("div.collapse2").children("#accelerator_type").siblings("#" + node).show();
				node = $(this).next("div.collapse2").children("#sintegrator_type").attr("value");
				$(this).next("div.collapse2").children("#sintegrator_type").siblings("#" + node).show();
//				node = $(this).next("div.collapse2").children("#camera_type").change();
				$(this).next("div.collapse2").slideToggle(300);
				// node = $(this).next("div.collapse").children("#environment_light_type").attr("value");
				// $(this).next("div.collapse").children("#environment_light_type").siblings("#" + node).show();
			}
		);
				
		$("#settings_panel #sintegrator_type").change(
			function()
			{
				//alert("#"+this.value);
				nodes = $(this).nextAll().hide();
				nodes = $(this).nextAll("#" + this.value).show();
			}
		);

		
		$("#settings_panel #accelerator_type").change(
			function()
			{
				//alert("#"+this.value);
				nodes = $(this).nextAll().hide();
				nodes = $(this).nextAll("#" + this.value).show();
			}
		);
		
		$("#export_file_path_browse").click(
			function()
			{
				window.location = 'skp:open_dialog@new_export_file_path'
			}
		)
                
        $("#export_luxrender_path_browse").click(
            function()
            {
                window.location = 'skp:open_dialog@change_luxpath'

            }
        ) 
                  
		
		$("#map_file_path_browse").click(
			function()
			{
				window.location = 'skp:open_dialog@load_env_image'
			}
		)
		
		//$("#current_view").click(
		//	function()
		//	{
		//		window.location = 'skp:get_view_size';
		//	}
		//);
		
		//$("#flip_dim").click(
		//	function()
		//	{
		//		width = $("#fleximage_xresolution").val();
		//		height = $("#fleximage_yresolution").val();
		//		$("#fleximage_xresolution").val(parseInt(height));
		//		$("#fleximage_yresolution").val(parseInt(width));
		//		window.location = 'skp:set_image_size@' + height + 'x' + width;
		//	}
		//);
		
		//$("#x800, #x1024, #x1280, #x1440, #x1080, #x1920").click(
		//	function()
		//	{
		//		window.location = 'skp:set_image_size@' + this.value + 'xtrue';
		//	}
		//);

		//$("#multiply_by_2, #divide_by_2").click(
		//	function()
		//	{
		//		width = $("#fleximage_xresolution").val();
		//		height = $("#fleximage_yresolution").val();
		//		switch(this.id)
		//		{
		//			case 'multiply_by_2':
		//				width *= 2;
		//				height *= 2;
		//				break;
		//			case 'divide_by_2':
		//				width /= 2;
		//				height /= 2;
		//				break;
		//		}
		//		$("#fleximage_xresolution").val(parseInt(width));
		//		$("#fleximage_yresolution").val(parseInt(height));
		//		window.location = 'skp:set_image_size@' + width + 'x' + height + 'xfalse';
		//	}
		//);
        
        //$("#fleximage_xresolution").on('change', function()
         //   {
          //      alert ("hi there")
           // }
        //)
                  

                  
		
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
		
	}
);
