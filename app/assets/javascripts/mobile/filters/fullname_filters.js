angular.module('workships-mobile.filters').filter('fullnameFilter', function () {
    function normalize(text) {
        return text.toLowerCase().trim();
    }

    return function(items, search_input) {
        var filtered = [];

        var searchTextFirst = normalize(search_input.firstname || '');
        var searchTextLast = normalize(search_input.lastname || '');

        angular.forEach(items, function(item) {
            var nameParts = item.name.split(' ');
            var firstName = normalize(nameParts[0] || '');
            var lastName = normalize(nameParts[1] || '');

            if (firstName.startsWith(searchTextFirst) && lastName.startsWith(searchTextLast)) {
                filtered.push(item);
            }
        });

        return filtered;
    };
});