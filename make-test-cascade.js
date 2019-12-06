/**
 * This script generates and injects path ignore rules for github actions
 * Based on this comment:
 * https://github.com/ethereumjs/ethereumjs-vm/issues/561#issuecomment-558943311
 */

const yaml = require('js-yaml')
const fs = require('fs')
const path = require('path')

/**
 * For each file, define which other tests should be ignored for each git pushhh
 * Based on the diagram:
 * https://github.com/ethereumjs/ethereumjs-vm/issues/561#issuecomment-558943311
 */ 
const ignorePaths = {
    'account':    ['block', 'blockchain', 'common', 'tx', 'vm'],
    'block':      ['account', 'common', 'tx'],
    'blockchain': ['account', 'block', 'common', 'tx'],
    'common':     ['block', 'blockchain', 'tx', 'vm'],
    'tx':         ['account', 'common', 'vm'],
    'vm':         ['account', 'block', 'blockchain', 'common', 'tx'],
}


const makeIgnorePaths = (p) => ignorePaths[p].map(v => `packages/${v}/**`)

const basePath = path.resolve('./ethereumjs-vm/.github/workflows')

const workflowFiles = fs.readdirSync(basePath)
console.log(workflowFiles);

workflowFiles.map(file => {
    // blockchain-test.yml -> blockchain
    const packageName = file.match(/^\w+/)[0]

    // If we don't have rules for this package, we move along.
    if (!ignorePaths.hasOwnProperty(packageName)) return;

    const filePath = path.join(basePath, file)

    const obj = yaml.safeLoad(fs.readFileSync(filePath, 'utf8'))
    
    obj.on = {
        push: {
            'paths-ignore': makeIgnorePaths(packageName)
        }
    }

    fs.writeFileSync(filePath, yaml.dump(obj))
    console.log(`Changes written to ${file}.`);
})