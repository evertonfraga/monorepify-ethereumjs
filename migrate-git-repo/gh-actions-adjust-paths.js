/**
 * This script adjusts all paths to the new file structure in GH Actions files.
 * - adds an ENV variable (cwd) to all Jobs
 * - injects `working-directory:` in all Steps that has `run:` key
 * - injects lerna bootstrap --ignore-scripts to link all matching packages locally
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
    
    for (const job in obj.jobs) {
        // Only injects CWD if needed
        let shouldInjectCwd = false

        for (const step in obj.jobs[job].steps) {
            const stepObject = obj.jobs[job].steps[step]
            
            // 1. Adds working-directory to each step run
            if (stepObject.run) {
                const workingDirectory = {'working-directory': '${{ env.cwd }}'}
                shouldInjectCwd = true

                obj.jobs[job].steps[step] = Object.assign(stepObject, workingDirectory)
            }
        }
    
        // 3. Adds env variable with path
        if(shouldInjectCwd) {
            const envCwd = { cwd: '${{github.workspace}}/packages/' + packageName }
            obj.jobs[job]['env'] = Object.assign(obj.jobs[job]['env'] || {}, envCwd)
        }
    }

    fs.writeFileSync(filePath, yaml.dump(obj))
    console.log(`Changes written to ${file}.`);
})
