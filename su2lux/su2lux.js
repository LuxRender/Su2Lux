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
	}
);
