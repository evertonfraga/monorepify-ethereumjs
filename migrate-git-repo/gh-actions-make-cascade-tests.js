/**
 * This script generates and injects path ignore rules for github actions
 * Based on this comment:
 * https://github.com/ethereumjs/ethereumjs-vm/issues/561#issuecomment-558943311
 */

const yaml = require('js-yaml')
const fs = require('fs')
const path = require('path')

/**
 * For each file, define which other tests should be ignored for each git push
 * Based on the diagram:
 * https://github.com/ethereumjs/ethereumjs-vm/issues/561#issuecomment-558943311
 */ 
const packages = ['account', 'block', 'blockchain', 'common', 'tx', 'vm']
const downstreamPackages = {
    'account':    ['vm'],
    'block':      ['blockchain', 'vm'],
    'blockchain': ['vm'],
    'common':     ['block', 'blockchain', 'common', 'tx', 'vm'],
    'tx':         ['block', 'blockchain', 'vm'],
    'vm':         [],
}
let ignorePaths = {}

for(let r in downstreamPackages) {
    const packagesToTest = [... downstreamPackages[r], r]
    const exclude = packages.filter(e => !packagesToTest.includes(e))
    ignorePaths[r] = exclude
}

const makeIgnorePaths = (p) => ignorePaths[p].map(v => `packages/${v}/**`)

const basePath = path.resolve('./ethereumjs-vm/.github/workflows')

const workflowFiles = fs.readdirSync(basePath)

workflowFiles.map(file => {
    // blockchain-test.yml -> blockchain
    const packageName = file.match(/^\w+/)[0]

    const workflowType = file.match(/(\w+)\.yml$/)[1]
    // console.log(workflowType, packageName);

    if (workflowType !== 'test') return;
    
    // If we don't have rules for this package, move along.
    if (!ignorePaths.hasOwnProperty(packageName)) return;

    const filePath = path.join(basePath, file)
    const obj = yaml.safeLoad(fs.readFileSync(filePath, 'utf8'))

    if (obj.on.push)
    obj.on = {
        push: {
            'paths-ignore': makeIgnorePaths(packageName)
        }
    }
    // console.log(file, obj)
    fs.writeFileSync(filePath, yaml.dump(obj))
    console.log(`Changes written to ${file}.`);
})