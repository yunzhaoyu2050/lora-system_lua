// var aesCmac = require('node-aes-cmac').aesCmac;
var aesCmac = require('../lib/aes-cmac.js').aesCmac;
// var crypto = require('crypto');
// Simple example.
// var const_Zero = new Buffer('0000000000000000');
// var key = 'k3Men*p/2.3j4abB';
// var message = 'this|is|a|test|message';
// var cipher = crypto.createCipheriv('aes128', key, const_Zero);
// var result=cipher.update(message);
// console.log(result)
// cipher.final();
// 有bug aesCmac函数传入字符串的情况下会死机
// var cmac = aesCmac(key, message);
// console.log(cmac)
// cmac will be: '0125c538f8be7c4eea370f992a4ffdcb'

// Example with buffers.
var bufferKey = new Buffer('6b334d656e2a702f322e336a34616242', 'hex');
var bufferMessage = new Buffer('asdasdas=asdasdasdas');
var options = {returnAsBuffer: true};
cmac = aesCmac(bufferKey, bufferMessage, options);
console.log(cmac)
// cmac will be a Buffer containing:
// <01 25 c5 38 f8 be 7c 4e ea 37 0f 99 2a 4f fd cb>