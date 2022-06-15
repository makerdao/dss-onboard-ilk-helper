// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.14;

import "forge-std/Test.sol";
import {DappTemplate} from "./DappTemplate.sol";

contract DappTemplateTest is Test {
  DappTemplate template;

  function setUp() public {
    template = new DappTemplate();
  }

  function testFailBasicSanity() public {
    assertTrue(false);
  }

  function testBasicSanity() public {
    assertTrue(true);
  }
}
