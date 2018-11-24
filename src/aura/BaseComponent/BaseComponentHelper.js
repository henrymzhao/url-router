/**
 * Created by Henry on 11/3/2018.
 */
({
    getSettings: function (cmp) {
        return new Promise($A.getCallback(function(resolve, reject) {
            let action = cmp.get('c.getSettings');
            action.setCallback(this, function (a) {
                let res = a.getState();
                if (res === "SUCCESS") {
                    let ret = a.getReturnValue();
                    console.log('BaseComponentHelper.js ::', ret);
                    cmp.set('v.doraemon', ret);
                    resolve(res);
                } else {
                    console.log('There was an error in BaseComponentHelper.js');
                    console.log('STATE: ' + res, a.getError()[0].message);
                    reject(res)
                }
            });
            $A.enqueueAction(action);
        }));
    }
})