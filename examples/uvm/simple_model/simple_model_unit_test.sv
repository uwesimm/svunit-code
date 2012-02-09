//###############################################################
//
//  Licensed to the Apache Software Foundation (ASF) under one
//  or more contributor license agreements.  See the NOTICE file
//  distributed with this work for additional information
//  regarding copyright ownership.  The ASF licenses this file
//  to you under the Apache License, Version 2.0 (the
//  "License"); you may not use this file except in compliance
//  with the License.  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.
//
//###############################################################

import svunit_pkg::*;

`include "svunit_defines.svh"

//---------------------------------------------
// the svunit_uvm_test is required for testing
// uvm_components
//---------------------------------------------
`include "svunit_uvm_test.sv"


//------------------------------------------
// include the dut and the transaction type
//------------------------------------------
`include "simple_model.sv"
`include "simple_xaction.sv"

typedef class c_simple_model_unit_test;

module simple_model_unit_test;
  string name = "simple_model_ut";
  c_simple_model_unit_test unittest;

  function void setup();
    unittest = new(name);
  endfunction
endmodule

class c_simple_model_unit_test extends svunit_testcase;

  //===================================
  // This is the class that we're 
  // running the Unit Tests on
  //===================================
  simple_model my_simple_model;


  //-------------------------------------------
  // for testing purposes, add fifos and ports
  // to interact with the simple_model
  //-------------------------------------------
  uvm_blocking_put_port #(simple_xaction) put_port;
  uvm_tlm_fifo #(simple_xaction) in_fifo;
                                                                                                     
  uvm_tlm_fifo #(simple_xaction) out_fifo;
  uvm_blocking_get_port #(simple_xaction) get_port;
 
 
  //===================================
  // Constructor
  //===================================
  function new(string name);
    super.new(name);

    //---------------------------------------------
    // build an instance of the simple model along
    // with test fifos on the input and output
    //---------------------------------------------
    my_simple_model = simple_model::type_id::create({ name , "::my_simple_model" }, null);

    put_port = new({ name , "::put_port" }, null);
    in_fifo = new({ name , "::in_fifo" }, null);

    out_fifo = new({ name , "::out_fifo" }, null);
    get_port = new({ name , "::get_port" }, null);


    //---------------------------------------------
    // make the connections to the simple model IO
    //---------------------------------------------
    my_simple_model.get_port.connect(in_fifo.get_export);
    put_port.connect(in_fifo.put_export);

    my_simple_model.put_port.connect(out_fifo.put_export);
    get_port.connect(out_fifo.get_export);


    //------------------------------------------------------
    // deactivate the simple_model to start. this assigns
    // the component to the idle domain which effectively
    // disconnects it from the run phases in the uvm domain
    //------------------------------------------------------
    svunit_deactivate_uvm_component(my_simple_model);
  endfunction


  //===================================
  // Setup for running the Unit Tests
  //===================================
  task setup();
    //---------------------------------------------------
    // activate the component (i.e. add the component to
    // the default uvm_domain)
    //---------------------------------------------------
    svunit_activate_uvm_component(my_simple_model);


    //---------------------------
    // start the svunit_uvm_test
    //---------------------------
    svunit_uvm_test_inst("svunit_uvm_test");
  endtask


  //===================================
  // This is where we run all the Unit
  // Tests
  //===================================
  task run_test();
    super.run_test();
  endtask


  `SVUNIT_TESTS_BEGIN


  //************************************************************
  // Test:
  //   get_port_not_null_test
  //
  // Desc:
  //   test for the existance of the simple_model::get_port
  //************************************************************
  `SVTEST(get_port_not_null_test)
    svunit_uvm_test_start();

    `FAIL_IF(my_simple_model.get_port == null);

    svunit_uvm_test_finish();
  `SVTEST_END(get_port_not_null_test)



  //************************************************************
  // Test:
  //   get_port_active_test
  //
  // Desc:
  //   ensure that objects put to the input are consumed once
  //   the component is started
  //************************************************************
  `SVTEST(get_port_active_test)
    begin
      simple_xaction tr = new();

      svunit_uvm_test_start(); 
      put_port.put(tr);
      #1;
      `FAIL_IF(!in_fifo.is_empty());
      svunit_uvm_test_finish();
      #1 out_fifo.flush();
    end
  `SVTEST_END(get_port_active_test)



  //************************************************************
  // Test:
  //   put_port_active_test
  //
  // Desc:
  //   ensure that objects put to the input are consumed and
  //   sent out on the get_port
  //************************************************************
  `SVTEST(put_port_active_test)
    begin
      time put_time;
      simple_xaction tr = new();

      svunit_uvm_test_start();
      put_time = $time;
      put_port.put(tr);
      get_port.get(tr);
      `FAIL_IF(put_time != $time);
      svunit_uvm_test_finish();
    end
  `SVTEST_END(put_port_active_test)



  //************************************************************
  // Test:
  //   xformation_test
  //
  // Desc:
  //   ensure that objects going through the simple model have
  //   their field property updated appropriately (multiply by
  //   2)
  //************************************************************
  `SVTEST(xformation_test)
    begin
      simple_xaction in_tr = new();
      simple_xaction out_tr;

      void'(in_tr.randomize() with { field == 2; });

      svunit_uvm_test_start(); 
      put_port.put(in_tr);
      get_port.get(out_tr);

      `FAIL_IF(in_tr.field != 2);
      `FAIL_IF(out_tr.field != 4);
      svunit_uvm_test_finish();
    end
  `SVTEST_END(xformation_test)

  `SVUNIT_TESTS_END


  //===================================
  // Here we deconstruct anything we 
  // need after running the Unit Tests
  //===================================
  task teardown();
    super.teardown();
    /* Place Teardown Code Here */

    //----------------------------------------------------------
    // deactivate the component so that it doesn't interfere
    // with subsequent unit tests (i.e. reassign it to the idle
    // domain)
    //----------------------------------------------------------
    svunit_deactivate_uvm_component(my_simple_model);
  endtask

endclass
