
<script>

	var max_usuragomme =100;
	var max_livellobenzina =200;

	$(function() {
	$( "#slider-livellobenzinapitstop" ).slider({
		range: "min",
		value: 0,
		min: 0,
		max: max_livellobenzina,
		slide: function( event, ui ) {
		$( "#livellobenzinapitstop_set" ).val( "" + ui.value );
	}
	});
	$( "#livellobenzinapitstop_set" ).val( "" + $( "#slider-livellobenzinapitstop" ).slider( "value" ) );
	});

	$(function() {
	$( "#slider-usuragommestop" ).slider({
		range: "min",
		value: 0,
		min: 0,
		max: max_usuragomme,
		slide: function( event, ui ) {
		$( "#usuragommestop_set" ).val( "" + ui.value );
	}
	});
	$( "#usuragommestop_set" ).val( "" + $( "#slider-usuragommestop" ).slider( "value" ) );
	});
	
	
	$(function() {
	$( "#slider-livellobenzinastop" ).slider({
		range: "min",
		value: 0,
		min: 0,
		max: max_livellobenzina,
		slide: function( event, ui ) {
		$( "#livellobenzinastop_set" ).val( "" + ui.value );
	}
	});
	$( "#livellobenzinastop_set" ).val( "" + $( "#slider-livellobenzinastop" ).slider( "value" ) );
	});
	
	$(function() {
	$( "#slider-usuragomme" ).slider({
		range: "min",
		value: 0,
		min: 0,
		max: max_usuragomme,
		slide: function( event, ui ) {
	}
	});
	});	
	
	$(function() {
	$( "#slider-livellobenzina" ).slider({
		range: "min",
		value: 0,
		min: 0,
		max: max_livellobenzina,
		slide: function( event, ui ) {
	}
	});
	});	
		
		
</script>



