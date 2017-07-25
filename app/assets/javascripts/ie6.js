// ie6.js
$(function() {
	if ($.browser.msie && parseInt($.browser.version, 10) === 6) {
		$('.row div[class^="span"]:last-child').addClass('last-child');
        $('[class*="span"]').addClass('margin-left-20');
        $(':button[class="btn"], :reset[class="btn"], :submit[class="btn"], input[type="button"]').addClass('button-reset');
        $(':checkbox').addClass('input-checkbox');
        $('.pagination li:first-child a').addClass('pagination-first-child');

        $('.btn-ie6').each(
            function() {
                $(this).click(function() {
                    msg = "You are about to delete this form in progress for CYCLE_ID " + $(this).attr('id')
                        + ". This action cannot be undone. Are you sure you want to delete this form?" 
                    return window.confirm(msg);
                });
            }
        );
        
	}
}); 