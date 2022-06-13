const Mushroom = artifacts.require('Mushroom');

module.exports = (deployer) => {
  deployer.deploy(Mushroom);
};
