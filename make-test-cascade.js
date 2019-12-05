/**
 * This script generates and injects path ignore rules for github actions
 * Based on this comment:
 * https://github.com/ethereumjs/ethereumjs-vm/issues/561#issuecomment-558943311
 */

const yaml = require('js-yaml')
const fs = require('fs')
const path = require('path')
const repos = [
    'account',
    'block',
    'blockchain',
    'testing',
    'tx',
    'vm'
]

/**
 * For each file, define which other tests should be ignored for each git pushhh
 * Based on the diagram:
 * https://github.com/ethereumjs/ethereumjs-vm/issues/561#issuecomment-558943311
 */ 
const ignorePaths = {
    'account':    ['block', 'blockchain', 'common', 'testing', 'tx', 'vm'],
    'block':      ['account', 'common', 'testing', 'tx'],
    'blockchain': ['account', 'block', 'common', 'testing', 'tx'],
    'common':     ['block', 'blockchain', 'tx', 'vm'],
    'testing':    ['account', 'block', 'blockchain', 'common', 'tx'],
    'tx':         ['account', 'common', 'testing', 'vm'],
    'vm':         ['account', 'block', 'blockchain', 'common', 'testing', 'tx'],
}


const makeIgnorePaths = (p) => ignorePaths[p].map(v => `packages/${v}/**`)

const basePath = path.resolve('./ethereumjs-vm/.github/workflows')

const workflowFiles = fs.readdirSync(basePath)
console.log(workflowFiles);

workflowFiles.map(file => {
    // blockchain-test.yml -> blockchain
    const packageName = file.match(/^\w+/)[0]
    console.log('PREFIX:', packageName);

    // If we don't have rules for this package, we move along.
    if (!ignorePaths.hasOwnProperty(packageName)) return;

    const filePath = path.join(basePath, file)
    console.log(filePath);

    const obj = yaml.safeLoad(fs.readFileSync(filePath, 'utf8'))
    
    obj.on = {
        push: {
            'paths-ignore': makeIgnorePaths(packageName)
        }
    }

    fs.writeFileSync(filePath, yaml.dump(obj))
    console.log(yaml.dump(obj));

})