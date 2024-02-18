import { expect } from "chai";
import { ethers } from "hardhat";
import { Foo } from "../../typechain-types";

describe("Foo contract", function () {
  let foo: Foo;

  beforeEach(async function () {
    // Deploy the Foo contract before each test
    const Foo = await ethers.getContractFactory("Foo");
    foo = await Foo.deploy();
  });

  // Test case for the id function
  it("should return the same value passed", async function () {
    const testValue = 123;
    expect(await foo.id(testValue)).to.equal(testValue);
  });
});
