/**
 * Created by Henry on 11/3/2018.
 */
({
    init: function (cmp, evt, hlp) {
        console.log('BaseComponentController.js ::', 'init');
        hlp.getSettings(cmp)
            .then(
                //settings retrieved, time to activate router
                $A.getCallback(function(result) {
                    console.log('BaseComponentController.js ::', result);
                    hlp.urlRouter(cmp, cmp.get('v.pocket4d.routingLibrary'));
                }),
                $A.getCallback(function(error) {
                //    throw error in error logging framework
                })
            );
    }
})