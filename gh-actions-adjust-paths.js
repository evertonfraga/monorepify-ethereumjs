/**
 * This script adjusts all paths to the new file structure in GH Actions files.
 * - adds an ENV variable (cwd) to all Jobs
 * - injects `working-directory:` in all Steps that has `run:` key
 * - sets `path:` to Coveralls Action invocation
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
    
    // 1. Adds env variable with path
    for (const job in obj.jobs) {
        const envCwd = { cwd: '${{github.workspace}}/packages/' + packageName }
        obj.jobs[job]['env'] = Object.assign(obj.jobs[job]['env'] || {}, envCwd)

        for (const step in obj.jobs[job].steps) {
            const stepObject = obj.jobs[job].steps[step]
            
            // 2. Adds working-directory to each step run
            if (stepObject.run) {
                const workingDirectory = {'working-directory': '${{ env.cwd }}'}

                obj.jobs[job].steps[step] = Object.assign(stepObject, workingDirectory)
            }

            // 3. Sets path for Coverage reports
            if (stepObject.uses && stepObject.uses === 'coverallsapp/github-action@master') {
                const coverallsPath = {
                    'path-to-lcov': '${{ env.cwd }}/coverage/lcov.info'
                }
                obj.jobs[job].steps[step] = Object.assign(stepObject, coverallsPath)
            }
            
        }
    }

    fs.writeFileSync(filePath, yaml.dump(obj))
    console.log(`Changes written to ${file}.`);
})