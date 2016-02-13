$(document).ready(function() {
	var resizeTextarea = function (textarea) {
		var lines = textarea.value.split('\n');
		var width = textarea.cols;
		var height = 1;
		for (var i = 0; i < lines.length; i++) {
			var linelength = lines[i].length;
			if (linelength >= width) {
				height += Math.ceil(linelength / width);
			}
		}
		height += lines.length;
		textarea.rows = height;
	};
	
	$("#formatButton").click(function() {
		try {
			var raw_data = $("#rawData").val();
			json_data = JSON.parse(raw_data);
			$("#ControlsRow").show();
			$("#json").JSONView(json_data);
		}
		catch(e) {
			alert(" Not a valid json");
		}
	});
	
	$('#collapse-btn').on('click', function() {
		$('#json').JSONView('collapse');
	});
	$('#expand-btn').on('click', function() {
		$('#json').JSONView('expand');
	});
	$('#toggle-btn').on('click', function() {
		$('#json').JSONView('toggle');
	});
	$('#toggle-level1-btn').on('click', function() {
		$('#json').JSONView('toggle', 1);
	});
	$('#toggle-level2-btn').on('click', function() {
		$('#json').JSONView('toggle', 2);
	});
	$("#ControlsRow").hide();
	
	resizeTextarea($("#rawData")[0]);
	
	$("#newValueButton").click(function(){
		//get url part
		var parts = document.URL.split("/inspect/");
		var url = parts[0];
		var key = parts[1];
		console.log($("#rawData").val());
		$.ajax(url + "/update/" + key, {
			type: "POST",
			contentType: "application/json",
			data: $("#rawData").val(),
			success: function() {
				window.location.reload();
			},
			error: function(xhr, textStatus, errorThrown) {
				alert("error: "+textStatus + "_" + errorThrown);
			}
		});
	});
});
