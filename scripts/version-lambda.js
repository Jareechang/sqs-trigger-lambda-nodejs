const packageJson = require('../package.json');
const {exec} = require('child_process');
const fs = require('fs').promises;
const common = require('./common');

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

/*
 * 
 * Generate a versioned zip file based on the package json
 *
 * **/
async function generateLambdaS3ZipFile() {
    const fileName = `dist/main-${packageJson.version}.zip`;
    console.log('Creating new zip file...');
    return new Promise((resolve, reject) => {
        exec(`zip ${fileName} src/index.js`, (err, stdout, stderr) => {
            if (err) return reject(stderr);
            if (stdout) {
                console.log(`File created. name: ${fileName}`);
                return resolve(stdout);
            }
        });
    });
}

async function main() {
    // Clean folders / files
    await common.runClean();

    // Create new dist folder
    await fs.mkdir('dist');

    // Generate 
    await generateLambdaS3ZipFile();
}

main();
