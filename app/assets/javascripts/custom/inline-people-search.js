/*
 * Will look for and remove nulls from:
 *  first_name
 *  last_name
 *  email
 *  company_name
 */
function cleanJsonPerson(jsonPerson) {
  jsonPerson.first_name = ( jsonPerson.first_name == null ? "" : jsonPerson.first_name )  
  jsonPerson.last_name = ( jsonPerson.last_name == null ? "" : jsonPerson.last_name )  
  jsonPerson.email = ( jsonPerson.email == null ? "" : jsonPerson.email )  
  jsonPerson.company_name = ( jsonPerson.company_name == null ? "" : jsonPerson.company_name )  
  return jsonPerson
}

function updateSelectedPerson(personId, personName, personEmail, personCompanyName) {
	$("input#search").val(personName)
	$(".picked-person-name").html(personName)
	$(".picked-person-email").html(personEmail)
	$(".picked-person-company-name").html(personCompanyName)
	$("input#person_id").val(personId)	
}

function clearNewPersonForm() {
	$('#person_first_name', '#new_person').val('')
	$('#person_last_name', '#new_person').val('')
	$('#person_email', '#new_person').val('')
}

$("document").ready(function(){

  $("#new_person").bind("ajax:beforeSend", function(xhr, person){
    $(this).addClass('loading')
		$('.flash', '#new-person-popup').remove();
  });
	
  $("#new_person").bind("ajax:success", function(xhr, person){
    $(this).removeClass('loading')
    $(this).find("input:submit").removeAttr('disabled');
    person = cleanJsonPerson(person)
		updateSelectedPerson(person.id, person.first_name + " " + person.last_name, person.email, person.company_name)
		clearNewPersonForm()
    $("#new-person-popup").modal('hide')
  });

  $("#new_person").bind("ajax:error", function(xhr, status, error){
    $(this).find("input:submit").removeAttr('disabled');
    data = eval("(" + status.responseText + ")");
    $(this).removeClass('loading')
		$('#error', '#new-person-popup').after($(document.createElement('div')).addClass('flash').addClass('alert').addClass('alert-error').html(data.errors[0]));
  });
	
	$("input#search", "#the-details").autocomplete({
    html: true,
		minLength: 3,
		focus: function(event, person) { 
			event.preventDefault()
		},
    source: function(request, response) {
    	$.getJSON("/people?utf8=%E2%9C%93&commit=Search", { search: request.term }, function(people) {
				responsePeople = new Array();
		  
				$.each(people, function (i, person) {
				  person = cleanJsonPerson(person)
					responsePeople[i] =  "<div id='search-result-name'>"+ person.first_name +" "+ person.last_name +"</div>"
					responsePeople[i] += "<div id='search-result-email' class='search-result-details'>"+ person.email +"</div>"
					responsePeople[i] += "<div class='clear'></div>"
					responsePeople[i] += "<div id='search-result-company-name' class='search-result-details'>"+ person.company_name +"</div>"	
					responsePeople[i] +=  "<div id='search-result-id'>"+person.id+"</div>"				        
	      });
				response(responsePeople)
			});
  	},
    select: function(event, person) { 
      event.preventDefault()
			var personId = $(person.item.value).filter("#search-result-id").html()
			var personName = $(person.item.value).filter("#search-result-name").html()
			var personEmail = $(person.item.value).filter("#search-result-email").html()
			var personCompanyName = $(person.item.value).filter("#search-result-company-name").html()
      updateSelectedPerson(personId, personName, personEmail, personCompanyName)
    }
  });
});