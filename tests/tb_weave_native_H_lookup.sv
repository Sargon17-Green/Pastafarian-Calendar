`timescale 1ns/1ps
// Test-only Icarus random-access H_s(N) witness from a table natively
// computed by tb_weave_native_transfer. No Python-generated counts.
// 101594 fixed-width HEX records, descending s, ascending n;
// each record 5632 ASCII hex chars + LF = 5633 bytes.
// This is NOT a synthesizable ASIC RAM interface.
module tb_weave_native_H_lookup;
    localparam integer WIDTH=22528, MONTHS=45, BE_BYTES=2809;
    localparam integer REC_BYTES=5633, EXPECTED_RECORDS=101594;
    integer lengths[1:MONTHS],caps[1:MONTHS];
    integer probes[0:7];
    integer i,j,prefix,fd,offset,rcode,mutate,probe_no,cell_number;
    logic [WIDTH-1:0] value,reference_root;

    task automatic binary_word(input string path,
                               output logic [WIDTH-1:0] n);
        integer f,k,b;
        begin
            n='0;
            f=$fopen(path,"rb");
            if(f==0) $fatal(1,"NATIVE_H_INDEXED_MISSING_ROOT");
            for(k=BE_BYTES-1;k>=0;k=k-1) begin
                b=$fgetc(f);
                if(b<0) $fatal(1,"NATIVE_H_INDEXED_TRUNCATED_ROOT");
                n[k*8+:8]=b[7:0];
            end
            if($fgetc(f)!=-1)
                $fatal(1,"NATIVE_H_INDEXED_OVERSIZED_ROOT");
            $fclose(f);
        end
    endtask

    task automatic dump_word(input string path,
                             input logic [WIDTH-1:0] n);
        integer f,k;
        begin
            f=$fopen(path,"wb");
            if(f==0) $fatal(1,"NATIVE_H_INDEXED_OUTPUT_OPEN");
            for(k=BE_BYTES-1;k>=0;k=k-1)
                $fwrite(f,"%c",n[k*8+:8]);
            $fclose(f);
        end
    endtask

    task automatic lookup(input integer s, input integer n,
                          output logic [WIDTH-1:0] found);
        integer q,cell_offset,position,scan_result;
        begin
            if(s<1 || s>MONTHS || n<0 || n>caps[s])
                $fatal(1,"NATIVE_H_INDEXED_BAD_REQUEST");
            cell_offset=0;
            for(q=MONTHS;q>s;q=q-1)
                cell_offset=cell_offset+caps[q]+1;
            cell_offset=cell_offset+n;
            position=cell_offset*REC_BYTES;
            if(mutate!=0 && s==1 && n==caps[1])
                position=position+1;
            if($fseek(fd,position,0)!=0)
                $fatal(1,"NATIVE_H_INDEXED_SEEK_FAILURE");
            scan_result=$fscanf(fd,"%h",found);
            if(scan_result!=1)
                $fatal(1,"NATIVE_H_INDEXED_READ_FAILURE");
        end
    endtask

    initial begin
        lengths[1]=115;
        lengths[2]=108;
        lengths[3]=119;
        lengths[4]=109;
        lengths[5]=106;
        lengths[6]=81;
        lengths[7]=115;
        lengths[8]=114;
        lengths[9]=117;
        lengths[10]=120;
        lengths[11]=98;
        lengths[12]=52;
        lengths[13]=81;
        lengths[14]=97;
        lengths[15]=121;
        lengths[16]=97;
        lengths[17]=115;
        lengths[18]=96;
        lengths[19]=107;
        lengths[20]=61;
        lengths[21]=106;
        lengths[22]=115;
        lengths[23]=119;
        lengths[24]=39;
        lengths[25]=84;
        lengths[26]=103;
        lengths[27]=115;
        lengths[28]=107;
        lengths[29]=55;
        lengths[30]=119;
        lengths[31]=97;
        lengths[32]=50;
        lengths[33]=122;
        lengths[34]=110;
        lengths[35]=81;
        lengths[36]=54;
        lengths[37]=101;
        lengths[38]=83;
        lengths[39]=88;
        lengths[40]=40;
        lengths[41]=25;
        lengths[42]=77;
        lengths[43]=98;
        lengths[44]=122;
        lengths[45]=105;
        prefix=0;
        for(i=1;i<=MONTHS;i=i+1) begin
            prefix=prefix+lengths[i];
            caps[i]=prefix-i;
        end
        cell_number=0;
        for(i=1;i<=MONTHS;i=i+1)
            cell_number=cell_number+caps[i]+1;
        if(cell_number!=EXPECTED_RECORDS || caps[45]!=4199)
            $fatal(1,"NATIVE_H_INDEXED_BAD_DIMENSIONS");
        probes[0]=1;probes[1]=2;probes[2]=3;probes[3]=7;
        probes[4]=8;probes[5]=15;probes[6]=44;probes[7]=45;
        mutate=$test$plusargs("mutate_address");
        binary_word("build/native_H_root.bin",reference_root);
        fd=$fopen("build/native_H_table.hex","r");
        if(fd==0)
            $fatal(1,"NATIVE_H_INDEXED_MISSING_TABLE");
        for(probe_no=0;probe_no<8;probe_no=probe_no+1) begin
            j=probes[probe_no];
            lookup(j,caps[j],value);
            if(j==1 && value!==reference_root)
                $fatal(1,"NATIVE_H_INDEXED_ROOT_MISMATCH");
            dump_word($sformatf("build/native_H_read_s%0d_max.bin",j),value);
            lookup(j,caps[j]-1,value);
            dump_word($sformatf("build/native_H_read_s%0d_prev.bin",j),value);
            $display("NATIVE_H_INDEXED_PROBE_PASS started=%0d maxN=%0d",j,caps[j]);
        end
        $fclose(fd);
        $display("STAGE1_NATIVE_H_INDEXED_TABLE_LOOKUP_PASS probes=16 rows=45 cells=101594");
        $finish;
    end
endmodule
