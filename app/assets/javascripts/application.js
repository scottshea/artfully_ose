//= require jquery
//= require jquery_ujs
//= require jquery-lib
//= require_directory ./custom
//= require bootstrap
//= require_self

zebra = function(table) {
    $("tr", table).removeClass("odd");
    $("tr", table).removeClass("even");
    $("tr:even", table).addClass("even");
    $("tr:odd", table).addClass("odd");
};

bindControlsToListElements = function () {
  $(".detailed-list li").hover(
    function(){
      $(this).find(".controls").stop(false,true).fadeIn('fast');},
    function(){
      $(this).find(".controls").stop(false,true).fadeOut('fast');});
};

function createErrorFlashMessage(msg) {
	$('#heading').after($(document.createElement('div'))
							.addClass('flash')
							.addClass('error')
							.addClass('alert')
							.addClass('alert-error')
							.html('<span>'+msg+'</span>'));

	$(".close").click(function(){
		$(this).closest('.flash').remove();
	});
}

function setErrorMessage(msg) {
	if($('.flash').length > 0) {
		$('.flash').fadeOut(400, function() {
			$(this).remove();
			createErrorFlashMessage(msg);
		});
	} else {
		createErrorFlashMessage(msg);
	}
}

function createFlashMessage(msg) {
	$('#heading').after($(document.createElement('div'))
							.addClass('flash')
							.addClass('success')
							.addClass('alert')
							.addClass('alert-info')
							.html('<span>'+msg+'</span>'));

	$(".close").click(function(){
		$(this).closest('.flash').remove();
	});
}

function setFlashMessage(msg) {
	if($('.flash').length > 0) {
		$('.flash').fadeOut(400, function() {
			$(this).remove();
			createFlashMessage(msg);
		});
	} else {
		createFlashMessage(msg);
	}
}

$(document).ready(function() {
    
	/*********** NEW BOOTSTRAP JS ***********/
	$(".alert").alert();

  $('.email-popup').popover({trigger:'manual'})
                   .click(function(){ $(this).popover('toggle'); });

  if($.browser.mozilla) {
    $('.section-price-disabled *').css("pointer-events", "none");
  }

	$('.help').popover();
	$('.edit-message, .delete-message').popover({title: "Editing / Deleting", content: "We can only edit or delete manually entered donations.", placement: "bottom"});
	
	$('.dropdown-toggle').dropdown();
	
	$('#nag').modal('show');
  $('.artfully-tooltip').tooltip()
	
	/*********** NEW ARTFULLY JS ************/
	
	/*********** EXISTING ARTFUL.LY JS ******/

  $("form .description").siblings("input").focusin(function(){
    $("form .description").addClass("active");
  }).focusout(function(){
    $("form .description").removeClass("active");
  });

  $(".zebra tbody").each(function(){
    zebra($(this));
  });

  $(".close").click(function(){
    $(this).closest('.flash').remove();
  });

  $(".new-window").parents("form").attr("target", "_blank");

  $("#main-menu").hover(
    function(){$("#main-menu li ul").stop().animate({height: '160px'}, 'fast');},
    function(){$("#main-menu li ul").stop().animate({height: '0px'}, 'fast');}
  );

  $(".stats-controls").click(function(){
    $(this).parent("li").toggleClass("selected");
    $(this).siblings(".hidden-stats").slideToggle("fast");
    return false;
  });

  activateControls();

  $(".new-performance-link").click(function() {
    $("#new-performance-row").show();
    return false;
  });

  $(".cancel-new-performance-link").click(function() {
    $("#new-performance-row").hide();
    return false;
  });

  $(".checkall").click(function(){
    var isChecked = $(this).is(":checked");
    $(this).closest('form').find("input[type='checkbox']:enabled").each(function(index, element){
      element.checked = isChecked;
      $(element).change();
    });
  });

  $(".zebra tbody").each(function(){
    zebra($(this));
  });

  $(".search-help-popup").dialog({autoOpen: false, draggable:false, modal:true, width:700, title:"Search help"});
  $("#search-help-link").click(function(){
    $(".search-help-popup").dialog("open");
    return false;
  });

  $(".add-new-ticket-type-link").bind("ajax:complete", function(et, e){
    $("#newTicketType").html(e.responseText);
    $("#newTicketType").modal( "show" );
    return false;
  });

  $("#hear-action-link,.edit-action-link").bind("ajax:complete", function(et, e){
    $("#hear-action-modal").html(e.responseText);
    $("#hear-action-modal").modal( "show" );
    activateControls();
    return false;
  });

  $("#edit-order-link").bind("ajax:complete", function(et, e){
    $("#edit-order-popup").html(e.responseText);
    $("#edit-order-popup").modal( "show" );
    activateControls();
		touchCurrency();
    return false;
  });

  $(".new-note-link,.edit-note-link").bind("ajax:complete", function(et, e){
    $("#new-note-popup").html(e.responseText);
    $("#new-note-popup").modal( "show" );
    activateControls();
    return false;
  });

  var eventId = $("#calendar").attr("data-event");
  var resellerEventId = $("#calendar").attr("data-reseller-event");
  var organizationId = $("#calendar").attr("data-organization");
  if (eventId !== undefined) {
    $('#calendar').fullCalendar({
      height: 500,
      events: '/events/' + eventId + '.json',
      eventClick: function(calEvent, jsEvent, view){
        window.location = '/events/'+ eventId + '/shows/' + calEvent.id;
      }
    });
  } else if (resellerEventId !== undefined && organizationId !== undefined) {
    $('#calendar').fullCalendar({
      height: 500,
      events: '/organizations/' + organizationId + '/reseller_events/' + resellerEventId + '.json'
    });
  }
  $('#tabs').tabs({
      show: function(event, ui) {
          $('#calendar').fullCalendar('render');
      }
  });

  $('.tag.deletable').each(function() {
		createControlsForTag($(this));
  });

  $(".new-tag-form").bind("ajax:beforeSend", function(evt, data, status, xhr){
		tagText = validateTag()
    if(!tagText) { return false; }

    newTagLi = $(document.createElement('li'));
		newTagLi.addClass('tag').addClass('deletable').addClass('rounder').html(tagText).appendTo($('.tags'));
		$('.tags').append("\n");
		createControlsForTag(newTagLi);
    $('#new-tag-field').attr('value', '');

		bindControlsToListElements();
		bindXButton();
  });

  bindControlsToListElements();
  bindXButton();

  $(".delete").bind("ajax:beforeSend", function(evt, data, status, xhr){
    $(this).closest('.tag').remove();
  });

  $(".super-search").bind("ajax:complete", function(evt, data, status, xhr){
      $(".super-search-results").html(data.responseText);
      $(".super-search-results").removeClass("loading");
  }).bind("ajax:beforeSend", function(){
    $(".super-search-results").addClass("loading");
  });

  $('.editable .value').each(function(){
    var url = $(this).attr('data-url'),
        name = $(this).attr('data-name');

    $(this).editable(url, {
      method: "PUT",
      submit: "OK",
      cssclass: "jeditable form-inline",
      height: "15px",
      width: "150px",
      name: "person[" + name + "]",
      callback: function(value, settings){
        $(this).html(value[name]);
        $(this).trigger('done');
      },
      ajaxoptions: {
        dataType: "json"
      }
    });
  });

});



bindXButton = function() {
  $(".delete").bind("ajax:beforeSend", function(evt, data, status, xhr){
    $(this).closest('.tag').remove();
  });
};


validateTag = function() {
  var tagText = $('#new-tag-field').attr('value');
  if(!validTagText(tagText)) {
    $('.tag-error').text("Only letters, number, or dashes allowed in tags");
    return false;
  } else {
    $('.tag-error').text("");
    return tagText;
  }
}

/*
 * Validates alphanumeric and -
 */
validTagText = function(tagText) {
	var alphaNumDashRegEx = /^[0-9a-zA-Z-]+$/;
	return alphaNumDashRegEx.test(tagText);
};

createControlsForTag = function(tagEl) {
	var tagText = tagEl.html().trim();
	var subjectName = tagEl.parent("ul").attr('id').split("-")[0];
	var subjectId = tagEl.parent("ul").attr('id').split("-")[1];

	var deleteLink = '<a href="/'+subjectName+'/'+ subjectId +'/tag/'+ tagText +'" data-method="delete" data-remote="true" rel="nofollow">X</a>';
	var controlsUl =  $(document.createElement('ul')).addClass('controls');
	var deleteLi = $(document.createElement('li')).addClass('delete').append(deleteLink);

	controlsUl.append(deleteLi);

  tagEl.append(controlsUl);
	tagEl.append("\n");
};

function touchCurrency() {
  $(".currency").each(function(index, element){
		$(this).focus()
		$(this).mask()
	});
}

function activateControls() {
  $(".currency").each(function(index, element){
    var name = $(this).attr('name'),
        input = $(this),
        form = $(this).closest('form'),
        hiddenCurrency = $(document.createElement('input'));

    input.maskMoney({showSymbol:true, symbolStay:true, allowZero:true, symbol:"$"});
    input.attr({"id":"old_" + name, "name":"old_" + name});
    hiddenCurrency.attr({'name': name, 'type': 'hidden'}).appendTo(form);

    form.submit(function(){
      hiddenCurrency.val(Math.round( parseFloat(input.val().substr(1).replace(/,/,"")) * 100 ));
    });
  });

  $(".datepicker" ).datepicker({dateFormat: 'yy-mm-dd'});
	if (!Modernizr.inputtypes.date) {
		$('input[type="date"]').datepicker({
      dateFormat: 'yy-mm-dd'
    });
	}

  $('.datetimepicker').datetimepicker({dateFormat: 'yy-mm-dd', timeFormat:'hh:mm tt', ampm: true });
  if (!Modernizr.inputtypes.datetime) {
    $('input[type="datetime"],input[type="datetime-local"]').datetimepicker({
      dateFormat: 'yy-mm-dd',
      timeFormat:'hh:mm tt',
      ampm: true
    });
  }
	
  
}

function togglePrintPreview(){
    var screenStyles = $("link[rel='stylesheet'][media='screen']"),
        printStyles = $("link[rel='stylesheet'][href*='print']");

    if(screenStyles.get(0).disabled){
      screenStyles.get(0).disabled = false;
      printStyles.attr("media","print");
    } else {
      screenStyles.get(0).disabled = true;
      printStyles.attr("media","all");
  }
}
