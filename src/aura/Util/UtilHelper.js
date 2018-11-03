/**
 * Created by Henry on 11/3/2018.
 */
({
    /**
     * @author Groundswell - Henry Zhao - henry@gscloudsolutions.com
     * @date 11/3/2018
     *
     * @description Core URL Routing logic for routing framework
     */
    urlRouter: function (cmp, library, urlObject) {
        debugger;
        let rawUrlComponents = this.__getUrlObjectByUrl(location.pathname, location.hash);
        urlObject = this.__getUrlObjectByComponents(rawUrlComponents, library);
        console.log('UtilHelper.js ::', urlObject);

    },

    /*******************************************************************************************************
    * @description parses a raw URL and extracts the necessary raw components for further processing
    * @param pathname - location.pathname
    * @param hash   -   location.hash
    * @return a raw list of url components, used for further processing in __getUrlObjectByComponents
    * @example __getUrlObjectByUrl(location.pathname, location.hash, library)
    */
    __getUrlObjectByUrl: function (pathname, hash) {
        let ret = {};
        let firstSplit = pathname.split('/s/');
        //grab community
        let community = firstSplit[0].replace('/', '');
        if (community === '' || typeof community === 'undefined') {
            ret.community = null;
        } else {
            ret.community = community;
        }

        //grab page
        if (firstSplit[1] === '') {
            ret.page = null;
        } else {
            ret.page = firstSplit[1];
        }
        //TODO consider returning null here
        //parse hash
        if (hash !== '') {
            ret.hash = hash.replace('#/', '');
        } else {
            ret.hash = null;
        }

        return ret;
    },

    /*******************************************************************************************************
    * @description takes a raw URL component list, and return either a corresponding URL_Router_Setting__mdt record, or a fallback option
    * @param urlObjectComponents    -   a list of raw URL components
    * @param library    -   library containing all URL_Router_Setting__mdt records
    * @return a URL_Router_Setting__mdt record
    */
    __getUrlObjectByComponents: function (urlObjectComponents, library) {
        let ret = {};
        let urlDataStack = [];
        let linkObject;
        let found = false;

        if (urlObjectComponents.community === null) {
        //    completely broken, can't even find a community
            console.log('UtilHelper.js ::', 'completely broken, can\'t even find a community');
            return -1;
        }
        if (urlObjectComponents.hash === null) {
            //    hash is null, so render default url for page
            return this.__handleInvalidUrlFallback(urlObjectComponents, library, 'page');
        }
        if (urlObjectComponents.page === null) {
        //    page is null, so render default page for community
            return this.__handleInvalidUrlFallback(urlObjectComponents, library, 'community');
        }

        while (found === false && urlObjectComponents.hash !== '') {
            // linkObject = library.find(x => x.URL_Extension__c === urlObjectComponents.hash);
            linkObject = library.find(function (x) {
                return x.Community__c.toLowerCase() === urlObjectComponents.community.toLowerCase() &&
                    x.Community_Page__c.toLowerCase() === urlObjectComponents.page.toLowerCase() &&
                    x.URL_Extension__c.toLowerCase() === urlObjectComponents.hash.toLowerCase()
            });
            if (typeof linkObject !== 'undefined') {
                found = true;
            } else {
                urlObjectComponents.hash = urlObjectComponents.hash.split('/');
                urlDataStack.unshift(urlObjectComponents.hash.pop());
                urlObjectComponents.hash = urlObjectComponents.hash.join('/');
            }
        }
        if (found === false) {
            //    throw error, invalid URL
            // linkObject = this.__handleInvalidUrlFallback(this.__getUrlObjectByUrl(location.pathname, location.hash, library), library);
        }
        ret.linkObject = linkObject;
        // set urlData if exists
        if (urlDataStack.length > 0) {
            // urlData is the data string from url being passed to child urlObjectComponents
            ret.urlData = urlDataStack.join('/');
        } else {
            ret.urlData = '';
        }
        ret.compiledUrlExtension = urlDataStack.length > 0 ? linkObject.URL_Extension__c + '/' + urlDataStack.join('/') : linkObject.URL_Extension__c;

        return ret;
    },

    __handleInvalidUrlFallback: function (urlComponents, library, fallback) {
        let ret;
        switch (fallback) {
            case 'community':
                ret = library.find(x => {
                   return x.Community__c.toLowerCase() === urlComponents.community.toLowerCase() &&
                   x.Default_For_Community__c === true;
                });
                break;
            case 'page':
                ret = library.find(x => {
                    return x.Community__c.toLowerCase() === urlComponents.community.toLowerCase() &&
                        x.Community__c.toLowerCase() === urlComponents.page.toLowerCase() &&
                        x.Default_For_Page__c === true;
                });
                break;
            default:
                console.log('UtilHelper.js ::', 'hit irreversible error, must throw error handling base page');
        }

        return ret;
    }
})