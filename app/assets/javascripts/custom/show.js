$(document).ready(function () {
  $("form.destroyable").live("ajax:before", function(){
		var row = $(this).closest("tr")
    row.remove();
  });

  $("form.destroyable").live("ajax:success", function(ev){
    setFlashMessage("The show has been deleted");
		ev.stopImmediatePropagation()
  });

  $("form.destroyable").live("ajax:error", function(ev){
    setErrorMessage("That show cannot be deleted");
		ev.stopImmediatePropagation()
  });

  $("form.sprited").live("ajax:before", function(){
    $(this).find("input:submit").attr('disabled','disabled');
  });

  $("form.sprited input:submit").live("click", function(event){
    var $dialog = $(this).siblings(".confirmation.dialog").clone(),
        $submit = $(this);

    if($dialog.length !== 0){
      event.preventDefault();
      event.stopImmediatePropagation();
      var $confirmation = $(document.createElement('input')).attr({type: 'hidden', name:'confirm', value: 'true'});

      $dialog.dialog({
        autoOpen: false,
        modal: true,
        buttons: {
          Cancel: function(){
            $submit.removeAttr('disabled');
            $dialog.dialog("close")
          },
          Ok: function(){
            $dialog.dialog("close")
            $submit.closest('form').append($confirmation);
            $submit.closest('form').submit();
            $confirmation.remove();
          }
        }
      });
      $dialog.dialog("open");
      return false;
    }
  });

  $("form.sprited").live("ajax:success", function(xhr, show){
    var $row = $(this).closest("tr");
    $(this).find(":submit").removeAttr('disabled');
    $row.removeClass("pending built published unpublished destroyable")
    $row.addClass(show.state);
		if(show.glance !== undefined) {
	    if(show.destroyable == true) {
				$row.addClass("destroyable");
			}
	    $row.find(".available_value").html(show.glance.tickets.available);
	    $row.find(".gross_value").html(show.glance.tickets.sold.gross);
	    $row.find(".comped_value").html(show.glance.tickets.comped);
		}
  });

  $("form.sprited").live("ajax:error", function(xhr, status, error){
    var data;

    $(this).find(":submit").removeAttr('disabled');
    data = eval("(" + status.responseText + ")");
    for(var i = 0; i < data.errors.length; i++){
      $.gritter.add({
        title: "Oops!",
        text: data.errors[i]
      });
    }
  });
});
