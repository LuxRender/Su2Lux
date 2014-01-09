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

function checkbox_expander(id)      // user interface, shows and hides interface fields for current material
{
    if ($("#" + id).attr("checked"))
	{
		if (id.match("show_advanced") || id.match("_use_")) {
			$("#" + id).nextAll(".basic").hide();
			$("#" + id).nextAll(".advanced").show();
		}
		$("#" + id).nextAll(".collapse_check").show();
	}
	else if ($("#" + id).attr("checked") == false)
	{
		if (id.match("show_advanced") || id.match("_use_")) {
			$("#" + id).nextAll(".basic").show();
			$("#" + id).nextAll(".advanced").hide();
		}
		$("#" + id).nextAll(".collapse_check").hide();
	}
}

function startactivemattype(){
    // loaded on opening SketchUp on OS X, on showing material dialog on Windows // triggered by window.location = 'skp:show_continued@'
		if ($("#material_name").val() == "bogus"){
			//alert ("not initialized");
			window.location = 'skp:start_refresh@' + this.id;
			window.location = 'skp:active_mat_type@'; 	// shows options for current material's material type
		}
	}
	
function startmaterialchanged() {
    window.location = 'skp:material_changed@' + this.value;
}

function setpreviewheight(previewsize,previewtime){
    // image and element size
    $("#preview").height(previewsize+16)
    $("#preview_image").height(previewsize)
    
    // dropdown values
    $("#previewtime").val(previewtime)
    $("#previewsize").val(previewsize)
    
    // preview button location
    verticalposition = previewsize - 20
    $("#update_material_preview").css('top',verticalposition+'px')
    
}
    
function update_RGB(fieldR,fieldG,fieldB,colorr,colorg,colorb){
    $(fieldR).val(colorr);
    $(fieldG).val(colorg);
    $(fieldB).val(colorb);
}

function show_load_buttons(textype,filename){
    //alert (textype)
    //alert ("show_load_buttons")
    idname = textype + '_texturetype';
    if ($('#'+idname).val()=="imagemap"){
        $('#'+idname).nextAll(".imagemap").show(); // shows  <span class="imagemap">
        $('#'+textype+'_imgmapname').text(filename)
    }
    // autoalpha
    if (textype=="aa"){
        $('#aa_imgmapname').text(filename)
    }
    
    // show color/texture area for custom metal2 material
    if ($("#metal2_preset").val()=="custom"){
        $(".metal2_custom").show();
    } else{
        $(".metal2_custom").hide();
    }
}

$(document).ready(
		
    function() {
        //alert ("document ready");
		
		$("#type").nextAll().hide(); // hides irrelevant material properties
		
		window.location = 'skp:show_continued@'
        
		
		$("#settings_panel select, :text").change( // triggered on changing dropdown menus or text fields
			function()
			{
                //alert ("detected!")
				window.location = 'skp:param_generate@' + this.id+'='+this.value
			}
		)
		
		$(":checkbox").click(
			function()
			{
                if(this.id=="use_architectural"){
                    //alert ("architectural")
                    window.location = 'skp:param_generate@' + this.id + '=' + $(this).attr('checked');
                     if($(this).attr('checked')){
                        $("#IOR_interface").hide()
                     }else{
                        $("#IOR_interface").show()
                     }
                }
                else if(this.id){
                    window.location = 'skp:param_generate@' + this.id + '=' + $(this).attr('checked');
                    checkbox_expander(this.id)
                }else{ // synchronize colorize checkboxes for "sketchup" and "imagemap" types
                    $("." + this.name).attr('checked', $(this).attr('checked'));
                    window.location = 'skp:param_generate@' + this.name + '=' + $(this).attr('checked');
                }
			}
		)

		$("#type").change(
			function() {
                //alert ("type change")
                $(this).nextAll().hide();
                $(this).nextAll("." + this.value).show();
                window.location = 'skp:type_changed@' + this.value;
			}
		)
                  
        $("#metal2_preset").change(
			function() {
                if ($("#metal2_preset").val()=="custom"){
                    $(".metal2_custom").show();
                } else{
                    $(".metal2_custom").hide();
                }
			}
		)
        
         $("#carpaint_name").change(
			function() {
                if ($("#carpaint_name").val()==""){
                    $("#diffuse").show();
                } else{
                    $("#diffuse").hide();
                }
			}
		)
        
        $("#material_name").change(
            function() {
                //alert (this);
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

        $(".header2").click(
            function()
            {
                //alert (this)
                expand_section($(this), "div.collapse", "+", "-");
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
                $(this).nextAll().hide();
                $(this).nextAll("." + this.value).show(); // shows image map interface elements
                // show auto alpha field
                if (this.value == "imagealpha" || this.value == "imagecolor"){
                    $("#autoalpha_image_field").show();
                }else if (this.value == "sketchupalpha"){
                    $("#autoalpha_image_field").hide();
                }
                // note: do not add window.location methods as they will interfere with .change functions on OS X
			}
		)

        $("#mx_texturetype").change(
            function()
            {
                $(this).nextAll("div").hide();
                $(this).nextAll("span").hide();
                $(this).nextAll("." + this.value).show();
            }
        );
                  
        $("#imagemap_filename").change(
            function()
               {
                    //alert(this.value)
                    $("#texture_preview").attr("src", this.value);
                    // store path for proper channel
                }
        )
 
        $("#dm_scheme").change(
            function()
            {
                if (this.value=="microdisplacement"){
                    $("#loop").hide();
                    $("#microdisplacement").show();
                }else{
                    $("#loop").show();
                    $("#microdisplacement").hide();
                }
            }
        );
        
        $('#previewsize').change(
            function()
            {
                //alert(this.value);
                window.location = 'skp:previewsize@' + this.value;
            }
        )
                  
        $('#previewtime').change(
            function()
            {
                //alert(this.value);
                window.location = 'skp:previewtime@' + this.value;
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





