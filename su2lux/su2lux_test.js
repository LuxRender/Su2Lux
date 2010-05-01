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

function js_select_preset(name)
{
	//report_id("su_select_preset", name);
	//alert("Selecting:" + $("#preset_select").html()); //for some reason it only works when this is on!
	//$("#presets_panel select").val(name);
	setTimeout(function() { $("#presets_panel select").val(name); }, 1)//hack to fix problem with IE6
}

function update_select_preset(name)
{
}

function su_select_preset(name)
{
	report_id("su_select_preset", name);
}

function set_preset_selector(name)
{
	$("#preset_select").append("<option value=" + name + ">" + name + "</option>");
}

function in_array(array, value){
	for(var i=0;i<array.length;i++)
	{
		if(array[i] == value)
		{
			return true;
		}
	}
	return false;
}

function new_preset()
{
	var preset_name = prompt("Preset Name:", "new_preset");
	if (preset_name){
		var values = jQuery.map(jQuery("#preset_select")[0].options, function(option)
			{
				return option.value;
			});
		if (in_array(values, preset_name))
		{
			var procede = confirm("Replace '" + preset_name + "'?");
			if(procede)
			{
				report_id("new_preset", preset_name);
				report_id("su_select_preset", preset_name);
			}
		}
		else
		{
			$("#preset_select").append("<option value=" + preset_name + ">" + preset_name + "</option>");
			report_id("new_preset", preset_name);
			report_id("su_select_preset", preset_name);//wish this could return value to sketchup instead of call here
		}
	}
}

function remove_preset()
{	
}

function selectop()
{

	var s = document.getElementById("preset_select");
	setTimeout(function() { s.options[1].selected = true; }, 1);//bug in IE6 took me ages to pinpoint
	//s.options[1].selected = true;
	var v = s.options[s.selectedIndex].value;
	//alert(v);
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
		
		$("#presets_panel select").change(//:text").change(
			function()
			{
				su_select_preset(this.value);
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
