$(document).ready(function() {
    navicon();
    navitab();
});

function navicon() {
    $('div.navicon').click(function() {
        $('nav.site').toggle();
    });
}

function navitab() {
    $('div.navitab-box-front').text('0');
    $('div.navitab').click(function() {
            navitabIncrement();
    });
}

function navitabIncrement() {
    var c = parseInt($('div.navitab-box-front').text());
    $('div.navitab-box-front').text(++c);
}
