<!--TODO add spinner plugin for number input field -->
function checkbox_expander(id)
{
	if ($("#" + id).attr("checked"))
	{
		if (id.match("show_advanced") || id.match("_use_")) {
			$("#" + id).nextAll(".basic").hide();
			$("#" + id).nextAll(".advanced").show();
		}
		$("#" + id).next(".collapse").show();
		$("#" + id).next(".collapse").children("#focus_type").change();
	}
	else if ($("#" + id).attr("checked") == false)
	{
		if (id.match("show_advanced") || id.match("_use_")) {
			$("#" + id).nextAll(".basic").show();
			$("#" + id).nextAll(".advanced").hide();
		}
		$("#" + id).next(".collapse").hide();
	}
}

$(document).ready(
	function()
	{

		$(".collapse").hide();
		$(".collapse2").hide();
		$(".advanced").hide();
        $("#firstsection").next(".collapse").show();
	
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
				$(this).nextAll().hide();
				$(this).nextAll("." + this.value).show();
			}
		);
		
		$("#settings_panel #pixelfilter_type").change(
			function()
			{
				$(this).nextAll().hide();
				$(this).nextAll("." + this.value).show();
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
				//alert("select preset");
				window.location = 'skp:preset@' + this.value;
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
		
		// $("#settings_panel #environment_light_type").change(
			// function()
			// {
				// nodes = $(this).next("div.collapse").hide();
				// nodes = $(this).nextAll("#" + this.value).show();
			// }
		// );
		
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
		
		$("#current_view").click(
			function()
			{	
				window.location = 'skp:get_view_size';
			}
		);
		
		$("#flip_dim").click(
			function()
			{	
				width = $("#fleximage_xresolution").val();
				height = $("#fleximage_yresolution").val();
				$("#fleximage_xresolution").val(parseInt(height));
				$("#fleximage_yresolution").val(parseInt(width));
				window.location = 'skp:set_image_size@' + height + 'x' + width;
			}
		);
		
		$("#x800, #x1024, #x1280, #x1440, #x1080, #x1920").click(
			function()
			{	
				window.location = 'skp:set_image_size@' + this.value + 'xtrue';
			}
		);

		$("#multiply_by_2, #divide_by_2").click(
			function()
			{	
				width = $("#fleximage_xresolution").val();
				height = $("#fleximage_yresolution").val();
				switch(this.id)
				{
					case 'multiply_by_2':
						width *= 2;
						height *= 2;
						break;
					case 'divide_by_2':
						width /= 2;
						height /= 2;
						break;
				}
				$("#fleximage_xresolution").val(parseInt(width));
				$("#fleximage_yresolution").val(parseInt(height));
				window.location = 'skp:set_image_size@' + width + 'x' + height + 'xfalse';
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
		
	}
);
