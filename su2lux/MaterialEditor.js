function expand_section(sender_id, section_id, closed_sign, opened_sign) {  // user interface: closes/opens panels
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

function checkbox_expander(id)      // user interface, switches between basic and advanced options (not currently in use)
{
	if ($("#" + id).attr("checked"))
	{
		if (id.match("show_advanced") || id.match("_use_")) {
			$("#" + id).nextAll(".basic").hide();
			$("#" + id).nextAll(".advanced").show();
		}
		$("#" + id).next(".collapse_check").show();
	}
	else if ($("#" + id).attr("checked") == false)
	{
		if (id.match("show_advanced") || id.match("_use_")) {
			$("#" + id).nextAll(".basic").show();
			$("#" + id).nextAll(".advanced").hide();
		}
		$("#" + id).next(".collapse_check").hide();
	}
}


function startactivemattype(){
    // loaded on opening SketchUp on OS X, on showing material dialog on Windows // triggered by window.location = 'skp:show_continued@'
		if ($("#material_name").val() == "bogus"){
			//alert ("not initialized");
			window.location = 'skp:start_refresh@' + this.id;
			window.location = 'skp:active_mat_type@'; 	// shows options for current material's material type
		}
		// todo: if material type is default, run param_generate function

	}
	
	
function startmaterialchanged() {
    window.location = 'skp:material_changed@' + this.value;
}

function flowtest(){
    alert ("working");
}
    
function update_RGB(fieldR,fieldG,fieldB,colorr,colorg,colorb){
    // alert (fieldR);
    // alert (colorr);
    $(fieldR).val(colorr);
    $(fieldG).val(colorg);
    $(fieldB).val(colorb);
}

function show_load_buttons(){
    //alert ("running show_load_buttons function");
    var theelements = $("[id*='_texturetype']");
    //alert (theelements.length);
    for (var i=0;i<theelements.length;i++){
        if (theelements[i].value=="imagemap"){
            $(theelements[i]).next(".imagemap").show(); // shows  <span class="imagemap">
        }
    }
}

$(document).ready(
		
    function() {
        //alert ("document ready");
		
		$("#type").nextAll().hide(); // hides irrelevant material properties
		
		window.location = 'skp:show_continued@'
        
		
		$("#settings_panel select, :text").change(
			function()
			{
				window.location = 'skp:param_generate@' + this.id+'='+this.value
			}
		)
		
		$(":checkbox").click(
			function()
			{
				window.location = 'skp:param_generate@' + this.id + '=' + $(this).attr('checked');
				checkbox_expander(this.id)
			}
		)

		$("#type").change(
			function() {
				$(this).nextAll().hide();                 
				$(this).nextAll("." + this.value).show();
				window.location = 'skp:type_changed@' + this.value;
			}
		)
        
        $("#material_name").change(
            function() {
				// alert (this.value);
                window.location = 'skp:material_changed@' + this.value;
            }
        )
		
		$("#settings_panel p.header").click(
			function()
			{
				expand_section($(this), "div.collapse", "+", "-");
				$(this).next("div.collapse").find("select").change();
				// checkbox_expander("use_diffuse_texture");
				$("input:checkbox").each(function(index, element) { checkbox_expander(element.id) } );
			}
		)
                  
            $("td.swatch").click(
            function()
            {
                // alert (this.id)
                window.location = 'skp:open_color_picker@' + this.id;
            }
        )
		
		$('select[id$="_imagemap_filtertype"]').change(
			function()
			{
				$(this).nextAll().hide();
				$(this).nextAll("." + this.value).show();
			}
		)
		
		$('select[id$="_texturetype"]').change(
			function()
			{
				$(this).next().hide();
				$(this).next("." + this.value).show(); // shows load button
			}
		)
		
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
		)
		
		$("#save_to_model").click(
			function()
			{
				window.location = 'skp:save_to_model';
			}
		)
		
		$("#reset").click(
			function()
			{
				window.location = 'skp:reset_to_default';
			}
		)
		
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
        
        $('input[id="update_material_preview"]').click(
            function()
            {
                window.location = 'skp:update_material_preview';
            }
        )
		
	}		
)





