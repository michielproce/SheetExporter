$(document).ready( function() {
    $("#export_to_clipboard").on("click", function(evt) {
        window.location = 'skp:export_to_clipboard';
    });

    $("#material-wrapper input[type=radio]").on("change", function () {
        var material = $("#material-wrapper input[type=radio]:checked").val();
        if(material === "other") {
            material = $("#material-other").val();
        }
        $("#material").val(material);
        window.location = 'skp:save_attribute@material';
    });

    $("#material-other").on("change", function (evt) {
        $(this).siblings("label").find("input[type=radio]").prop("checked", true).trigger("change");
    });

    $("#info").on("change keyup", function(evt) {
        window.location = 'skp:save_attribute@info';
    });

    $("#skip-checkbox").on("change", function(evt) {
        $("#skip").val($("#skip-checkbox").is(":checked"));
        window.location = 'skp:save_attribute@skip';
    });

    $("#rotate-checkbox").on("change", function(evt) {
        $("#rotate").val($("#rotate-checkbox").is(":checked"));
        update();
        window.location = 'skp:save_attribute@rotate';
    });

    $("#double-checkbox").on("change", function(evt) {
        $("#double").val($("#double-checkbox").is(":checked"));
        window.location = 'skp:save_attribute@double';
    });

    $("#split").on("change keyup", function(evt) {
        evt.preventDefault();
        var splitVal = $("#split").val();
        if (splitVal.trim() !== "") {
            var split = parseInt(splitVal);
            if (isNaN(split)) {
                split = 1;
            }

            $("#split").val(split);
        }


        window.location = 'skp:save_attribute@split';
    });


    $("#sheet").on("click", function (evt) {
        var newState = false;

        var $bands = $("#sheet .band");

        $bands.each(function(evt) {
            if(!$(this).hasClass("active")) {
                newState = true;
            }
        });

        $bands.toggleClass("active", !newState);
        $bands.trigger("click");
    });

    $("#sheet .band").on("click", function(evt) {
        evt.stopPropagation();
        var $band = $(this);

        $band.toggleClass("active");

        var $bandinput = $band.children("input");

        $bandinput.val($band.hasClass("active"));

        window.location = 'skp:save_attribute@' + $bandinput.attr("id");
    });


    window.onerror = function (msg, url, line) {
        $("#error").val("Sheet Javascript Error\n: " + msg + "\nurl: " + url + "\nline: " + line + "\n\n");
        window.location = 'skp:on_error'
    };

    window.location = 'skp:document_ready';
});


function read_hidden_fields() {
    $('#skip-checkbox').prop('checked', $("#skip").val() == 'true');
    $('#rotate-checkbox').prop('checked', $("#rotate").val() == 'true');
    $('#double-checkbox').prop('checked', $("#double").val() == 'true');

    var material = $("#material").val();
    $("#material-other").val('');
    if(material == '') {
        $("#material-wrapper input[type=radio][value='']").prop("checked", true);
    } else if(material =='Primary') {
        $("#material-wrapper input[type=radio][value='Primary']").prop("checked", true);
    } else if(material =='Secondary') {
        $("#material-wrapper input[type=radio][value='Secondary']").prop("checked", true);
    } else {
        $("#material-wrapper input[type=radio][value='other']").prop("checked", true);
        $("#material-other").val(material)
    }

   $("#sheet .band.back").toggleClass("active", $("#band-back").val() == 'true');
   $("#sheet .band.right").toggleClass("active", $("#band-right").val() == 'true');
   $("#sheet .band.front").toggleClass("active", $("#band-front").val() == 'true');
   $("#sheet .band.left").toggleClass("active", $("#band-left").val() == 'true');

    update();
}


function update() {
    if(!$("#rotate-checkbox").is(":checked")) {
        $("#sheet").removeClass("rotate");
        $("#size-text .no-rotate").show();
        $("#size-text .rotate").hide();
    }
    else {
        $("#sheet").addClass("rotate");
        $("#size-text .rotate").show();
        $("#size-text .no-rotate").hide();
    }
}