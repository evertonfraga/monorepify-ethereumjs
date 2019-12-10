/**
 * This script adjusts working-environment for each step
 * Based on this comment:
 * https://github.com/ethereumjs/ethereumjs-vm/issues/561#issuecomment-558943311
 */

const yaml = require('js-yaml')
const fs = require('fs')
const path = require('path')

const basePath = path.resolve('./ethereumjs-vm/.github/workflows')

const workflowFiles = fs.readdirSync(basePath)
console.log(workflowFiles);

workflowFiles.map(file => {
    // blockchain-test.yml -> blockchain
    const packageName = file.match(/^\w+/)[0]

    const filePath = path.join(basePath, file)
    const obj = yaml.safeLoad(fs.readFileSync(filePath, 'utf8'))
    
    // Adds env variable with path
    for (const job in obj.jobs) {
        const envCwd = { cwd: '${{github.workspace}}/package/' + packageName }
        obj.jobs[job]['env'] = Object.assign(obj.jobs[job]['env'] || {}, envCwd)

        // Adds working-directory to each step run
        for (const step in obj.jobs[job].steps) {
            if (obj.jobs[job].steps[step].run) {
                
                const stepObj = obj.jobs[job].steps[step]
                const workingDirectory = {'working-directory': '${{ env.cwd }}'}

                obj.jobs[job].steps[step] = Object.assign(stepObj, workingDirectory)
            }
        }
    }

    fs.writeFileSync(filePath, yaml.dump(obj))
    console.log(`Changes written to ${file}.`);
})