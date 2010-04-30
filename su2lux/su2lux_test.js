<!--TODO add spinner plugin for number input field -->
function checkbox_expander(id)
{
	if ($("#" + id).attr("checked"))
	{
		$("#" + id).next("div.collapse").show();
	}
	else if ($("#" + id).attr("checked") == false)
	{
		$("#" + id).next("div.collapse").hide();
	}
}

function report_id_val(action_callback, id, val)
{
	window.location = 'skp:' + action_callback + '@' + id + '=' + val;
}

function report_id(action_callback, id)
{
	window.location = 'skp:' + action_callback + '@' + id;
}

function change_setting(id, val)
{
	report_id_val('change_setting', id, val);
}

function call_function(id)
{
	report_id('call_function',id);
}

function init_collapse()
{
	$("#settings_panel .select_collapse").each(function(){
				nodes = $(this).nextAll("div.collapse").hide();
				nodes = $(this).nextAll("#" + this.value).show();
	}); //show all collapsed boxes
}

function select_preset(name)
{
	report_id("select_preset", name);
}

function set_preset_selector(name)
{
	$("#preset_select").append("<option value=" + name + ">" + name + "</option>");
}

function new_preset()
{
	preset_name = prompt("Preset Name:", "new_preset");
	alert("preset_name: " + preset_name);
	$("#preset_select").append("<option value=" + preset_name + ">" + preset_name + "</option>");
	report_id("new_preset", preset_name);
	report_id("select_preset", preset_name);
}

function remove_preset()
{	
}

jQuery.fn.fadeToggle = function(speed, easing, callback) {
   return this.animate({opacity: 'toggle'}, speed, easing, callback);
}; 
$(document).ready(
	function()
	{
		//$(".header").next("div.collapse").show();
		
		init_collapse();

		$("#settings_panel select, :text").change(
			function()
			{
				change_setting(this.id, this.value);
			}
		);
		
		$("#presets_panel select, :text").change(
			function()
			{
				select_preset(this.id);
			}
		);

		$(":checkbox").click(
			function()
			{
				if (this.checked == true)
				{
				val = "true"
				};
				if (this.checked == false)
				{
				val = "false"
				};
				checkbox_expander(this.id)
				change_setting(this.id, $(this).attr('checked'));
			}
		);

		$("p.header").click(
			function()
			{
				$(this).next("div.collapse").children().fadeToggle(500);
				$(this).next("div.collapse").slideToggle(500);
			}
		);
				
		$(".select_collapse").change(
			function()
			{
				//alert("#"+this.value);
				nodes = $(this).nextAll("div.collapse").hide();
				nodes = $(this).nextAll("#" + this.value).show();
			}
		);
		$(":button").click(
			function()
			{
				call_function(this.id)
			}
		);
	}
);
