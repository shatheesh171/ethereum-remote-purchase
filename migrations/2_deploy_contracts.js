const Purchase = artifacts.require("Purchase");

module.exports = function (deployer) {
  deployer.deploy(Purchase,{from:"0xdf2751F0a85468265c5d33A2736dbD098d2BF79d",value:web3.utils.toWei('10','ether')});
};
