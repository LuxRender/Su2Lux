<!--TODO add spinner plugin for number input field -->
$(document).ready(
	function()
	{

		$(".collapse").hide();

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
			}
		);
		
		$("#presets select").change(
			function()
			{
				//alert("select preset");
				window.location = 'skp:preset@' + this.value;
			}
		);

		$(":checkbox").change(
			function()
			{
				if ($(this).attr("checked"))
				{
					$(this).next(".collapse").show();
				}
				else
				{
					$(this).next(".collapse").hide();
				}
				window.location = 'skp:param_generate@' + this.id + '=' + this.checked;
			}
		);

		$("#settings_panel p.header").click(
			function()
			{
				$(this).next("div.collapse").slideToggle(300);
				node = $(this).next("div.collapse").children("#accelerator_type").attr("value");
				$(this).next("div.collapse").children("#accelerator_type").siblings("#" + node).show();
				node = $(this).next("div.collapse").children("#sintegrator_type").attr("value");
				$(this).next("div.collapse").children("#sintegrator_type").siblings("#" + node).show();
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
		
		$("#current_view").click(
			function()
			{	
				window.location = 'skp:get_view_size';
			}
		);
		
		$("#flip_dim").click(
			function()
			{	
				width = $("#xresolution").val();
				height = $("#yresolution").val();
				$("#xresolution").val(parseInt(height));
				$("#yresolution").val(parseInt(width));
				window.location = 'skp:set_image_size@' + height + 'x' + width;
			}
		);
		
		$("#x800, #x1024, #x1280, #x1440, #x1080, #x1920").click(
			function()
			{	
				window.location = 'skp:set_image_size@' + this.value;
			}
		);

		$("#multiply_by_2, #divide_by_2").click(
			function()
			{	
				width = $("#xresolution").val();
				height = $("#yresolution").val();
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
				$("#xresolution").val(parseInt(width));
				$("#yresolution").val(parseInt(height));
				window.location = 'skp:scale_view@' + width + 'x' + height;
			}
		);
		
	}
);
