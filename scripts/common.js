const {exec} = require('child_process');

/*
 * 
 * Cleans the dist folder 
 *
 * **/
async function runClean() {
    return new Promise((resolve, reject) => {
        exec('yarn run clean', (err, stdout, stderr) => {
            if (err) return reject(stderr);
            return resolve(stdout);
        });
    });
}

module.exports = {
    runClean
};
