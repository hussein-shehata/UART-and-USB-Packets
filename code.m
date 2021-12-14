fname = 'config.json';
fid = fopen(fname); 
raw = fread(fid,inf); 
str = char(raw'); 
fclose(fid); 
val = jsondecode(str);
name1=val.protocol_name;
name2=val.protocol_name_1;
ERROR_FLAG=0;
%***************checking the names***********
if ((strcmp(name1,'UART')))
    UART_data_bits= val.parameters.data_bits;
    UART_parity=val.parameters.parity;
    UART_stop_bits=val.parameters.stop_bits;
    UART_bit_duration=val.parameters.bit_duration;
    
    if (name2 == "USB")
        PID_length=val.parameters_1.pid;
        dest_addr=val.parameters_1.dest_address;
        payload=val.parameters_1.payload;
        bit_duration_usb=val.parameters_1.bit_duration;
    else 
        ERROR_FLAG=1;
        disp("ERROR")
    end
elseif(name1=="USB")
        % entered succesfully if the protocol name USB was found in the,
        % configuration file
        PID_length=val.parameters.pid;
        dest_addr=val.parameters.dest_address;
        payload=val.parameters.payload;
        bit_duration_usb=val.parameters.bit_duration;
        
        if(name2=="UART")
         % entered succesfully if the protocol name UART was found in the
         % configuration file
        UART_data_bits= val.parameters_1.data_bits;
        UART_parity=val.parameters_1.parity;
        UART_stop_bits=val.parameters_1.stop_bits;
        UART_bit_duration=val.parameters_1.bit_duration;       
            
            
        else
            ERROR_FLAG=1;
            disp("ERROR")
        end
else
    ERROR_FLAG=1;
    disp("ERROR");
end

%Reading input txt file
fname = 'inputdata.txt'; 
fid = fopen(fname); 
ASCI_input = fread(fid,inf); 
binary_data=dec2bin(ASCI_input,8);  

% UART PART
if(ERROR_FLAG==0)
    binary_data=dec2bin(ASCI_input,UART_data_bits); %reading the ASCI input and put it into vector
    
    %checking the parity of the UART
    
    if(UART_parity == "even")
       parity=1;
     elseif(UART_parity == "none")
        parity=0;
     elseif(UART_parity == "odd")
         parity=1;
    end
    
    %******************equations part***************************
    UART_efficiency_vector = [1:5]
    UART_overhead_vector = [1:5]
    UART_tx_vector = [1:5]
    UART_number_of_frames=0;
    for file_size = 1:5
    
    UART_efficiency = ((UART_data_bits)/((UART_data_bits)+(UART_stop_bits)+ (parity)+ 1))*100;
    UART_overhead =  100-UART_efficiency;
    UART_tx= 1280*file_size*((UART_data_bits) +(UART_stop_bits)+(parity)+1)*(UART_bit_duration);
    
    
    UART_overhead_vector(file_size)= UART_overhead
    UART_tx_vector(file_size)= UART_tx
    end
         
     
     % plotting UART_overhead vs file_size
     h6=figure(6);
     ax6=axes('parent',h6);
     plot(ax6,(1:5)*1280,UART_overhead_vector);
     xlabel(ax6,'file size in byte');
     ylabel(ax6,'UART Overhead');
     
     % plotting UART_txtime vs file_size
     h7=figure(7);
     ax7=axes('parent',h7);
     
     plot(ax7,(1:5)*1280,UART_tx_vector);
     xlabel(ax7,'file size in byte');
     ylabel(ax7,'UART Tx');
     
     %printing the value of UART efficiency and UART overhead
    disp("Uart_efficiency =" +UART_efficiency +"%");
    disp("Uart_overhead =" +UART_overhead +"%");
    disp("Uart_tx =" +UART_tx );
    
      
   
    firstbyte = binary_data(1,:); %take the first Byte
    firstbyte=str2double(firstbyte);
    firstbyte = num2str(firstbyte) - '0';
    if (length(firstbyte) ~= UART_data_bits)  % fix the removed 0 when the data byte starts with 0
    firstbyte = [0,firstbyte];
    end
    firstbyte=flip(firstbyte);  
    
    if (UART_stop_bits==2)
        no_stop_bits=[1,1];
    else
        no_stop_bits=[1];
    end
    
    %this code segment is responsible for generating the parity bits for the first byte to be
    %appended later
   if UART_parity ~="none"
        ones_counter=0;
        for iterations=1:length(firstbyte)
            if(firstbyte(iterations) ==1)
                ones_counter=ones_counter+1;
            end
        end
        if UART_parity=="even"
            if mod(ones_counter,2)==0
                parity_vector=[0];
            else
                parity_vector=[1];
            end
        else
            if mod(ones_counter,2)==0
                parity_vector=[1];
            else
                parity_vector=[0];
            end
        end
   end
    
    if UART_parity =="none"
        first_frame=[0,firstbyte,no_stop_bits];  %the frame of the first byte
    else
        first_frame=[0,firstbyte,parity_vector,no_stop_bits];  %the frame of the first byte if there was parity
    end
    
    secondbyte = binary_data(2,:);  %take the second Byte
    secondbyte=str2double(secondbyte);
    secondbyte = num2str(secondbyte) - '0';
    
    if (length(secondbyte) ~= UART_data_bits) % fix the removed 0 when the data byte starts with 0
    secondbyte = [0,secondbyte];
    end
    
    secondbyte=flip(secondbyte);
    %this code segment is responsible for generating the parity bits for the second byte to be
    %appended later
    if UART_parity ~="none"
        ones_counter=0;
        for iterations=1:length(secondbyte)
            if(secondbyte(iterations) ==1)
                ones_counter=ones_counter+1;
            end
        end
        if UART_parity=="even"
            if mod(ones_counter,2)==0
                parity_vector=[0];
            else
                parity_vector=[1];
            end
        else
            if mod(ones_counter,2)==0
                parity_vector=[1];
            else
                parity_vector=[0];
            end
        end
    end
    
    if UART_parity =="none"
        second_frame=[0,secondbyte,no_stop_bits];  %the frame of the second byte
    else
        second_frame=[0,secondbyte,parity_vector,no_stop_bits];  %the frame of the second byte if there was parity
    end
    
    final=[first_frame,second_frame];  % put the first 2 frame in a vector to plot it
    time= 0:1:19;
    x=length(final);
    z=linspace(0,0.0001*x,x);
     
    h5=figure(5);
    ax5=axes('parent',h5);
    stairs(ax5,z,final)  %plot the time diagram of the first 2 sent data bytes
    ylim([-2 3]);
    xlabel(ax5,'time')
    ylabel(ax5,'first 2 frames in UART')
    
    
   % USB MODE CODE
    
    binary_data=dec2bin(ASCI_input,8); %reading the ASCI input and put it into vector
    %sync_pattern=val.parameters.sync_pattern
    %sync_pattern=str2num(sync_pattern)
    sync_pattern=[0,0,0,0,0,0,0,1]; % make the sync pattern in a vector
    
    %PID_length=val.parameters.pid;
    
    %dest_addr=val.parameters.dest_address;
   % dest_addr=str2num(dest_addr)
    %payload=val.parameters.payload;
    %bit_duration_usb=val.parameters.bit_duration;
    
    
    %figuring out the number of required packets to send whole input bytes
    
    if(mod(1280,payload)==0)
       number_of_packets=1280/payload;

    else
       number_of_packets=(1280/payload);
       number_of_packets= ceil(number_of_packets);
    end
    PID=0;
    

    
    % this while loop is responsible for getting the number of rows we will
    % append to the input data matrix  
    flag=1;
    i=12;
    while (flag==1)
        if(mod(payload*8*i,8) ==0)
            flag=0;
        end
        i=i+1;
    end
    
    diff1=(payload*8*i)/8;
    diff2=diff1-1280;
    
    
    flip1=fliplr(binary_data);
    ERT=[flip1;ones(diff2,8)*'0'];
    flip2=ERT' ;
    data=reshape(flip2,payload*8,[]);  %the input data matrix
    
    dest_addr=dest_addr';
    dest_addr=str2num(dest_addr);
    dest_addr=dest_addr';
    PID_counter=0;
   
    %plot_packet_vp=0;
    
       
        PID_counter=0;
        for sent_packet=1:number_of_packets
            PID_counter= PID_counter+1;
            if(PID_counter == 16)
               PID_counter=1; 

            end

            

            data_packet=data(:,sent_packet);  %take packet from the data matrix
            data_packet=str2num(data_packet); %convert it to number vector 
            data_packet=data_packet';       %make it row vector 

            % this segment of code is responsible for making the PID 

            binary_vector = dec2bin(PID_counter,4);%convert the PID counter to binary number of 4 bits
            binary_vector = binary_vector'; %make it column
            binary_vector = str2num(binary_vector);  %convert it to number vector
            inverted_vector =[0,0,0,0];  %this vector will hold the inverted number of the PID counter
            
            %the following for loop is responsible for making the inverting
            %of the PID counter 
            for i = 1:length(binary_vector)
               if(binary_vector(i) == 1)
                   inverted_vector(i)=0;
               elseif(binary_vector(i) ==0)
                   inverted_vector(i)=1;
                end
            end
            
            binary_vector=binary_vector';
            binary_vector=fliplr(binary_vector);
            binary_vector=binary_vector';

            inverted_vector = fliplr(inverted_vector);
            inverted_vector = inverted_vector';
            PID=[inverted_vector ;binary_vector];
            PID=PID';  %PID vector now holds the inverted PID counter in the first 4 bits and the real PID counter in the second 4 bits

                
            frame=[sync_pattern,PID,dest_addr,data_packet]; %making the frame
            frame_length=length(frame);

            

            %responsible for stuffed bits
            counters_ones=0;
            for i=1:frame_length
                if(frame(1,i)==1)

                    counter_ones=counter_ones+1;
                    if (counter_ones==6)
                        frame=[frame(1:i),0,frame(i+1:end)];
                        counter_ones=0;
                    end
                else
                    counter_ones=0;
                end
            end

            %the following segment is responsible for making the NZRI frame
            frame_length=length(frame);
            previous_bit=1;
            NZRI_frame=[1];  %one for the idle state before the frame
            for i=1:frame_length
                %make the next bit is the inversion of the current bit if the bit in the frame is 0 
                if (frame(1,i) ==0)
                    if(previous_bit ==0)
                        bit=1;
                    else
                        bit=0;
                    end
                %make the next bit is the same of the current bit if the bit in the frame is 1 
                else
                    if(previous_bit ==0)
                        bit=0;
                    else
                        bit=1;
                    end
                end
              previous_bit=bit;

              NZRI_frame=[NZRI_frame,bit];  %append each bit in the NZRI frame to complete it

            end
            %save the first 2 packets to plot them later
            if(sent_packet <3)
                if(sent_packet ==1)
                    first_packet=NZRI_frame;
                elseif(sent_packet ==2)
                    second_packet=NZRI_frame;
                end
            end
            NZRI_frame=[NZRI_frame,0,0];  % end the NZRI frame with the stop packet bits
        end
        
        
        flag=0;
        
        length_total= length(NZRI_frame);
         
        
         efficiency_vector=1:0.3:5;
         overhead_vector= 1:0.3:5;
         tx_vector = 1:0.3:5;
         
         %*****************equations part****************
         efficiency_usb= ((1*length(binary_data)*8)/(number_of_packets*(length_total-1)))*100;
         disp("USB_efficiency = "+efficiency_usb +"%");
         total_time_usb = length(binary_data)*number_of_packets*0.0001;
         disp("USB tx time  = "+total_time_usb );
         overhead_usb = 100 - efficiency_usb;
         disp("USB overhead = "+overhead_usb +"%");
         
         %for loop to determine the number of packets needed by the USB
         %when the filesize changes so we can calculate efficiency and over
         %head and transimission time of USB
         loop_counter=1;
    for file_size = 1:0.3:5
        if(mod(file_size*length(binary_data),payload)==0)
        
            number_of_packets = file_size*length(binary_data)/payload;
            flag=0;
            remainder=0;
        else  
            number_of_packets = file_size*length(binary_data)/payload;
            remainder= number_of_packets - floor(number_of_packets);
            number_of_packets= floor(number_of_packets);
            flag=1;
         
        end
       
        %efficiency is calculated by dividing the useful bits(data of the
        %file) by the number of packets needed to transmit the file which
        %is multiplied by the total length of the NZRI frame, if the number
        %of packets needed is not a whole number (10.55, 11.661... etc) we
        %will take the remainder and multiply it by the payload to find how
        %many bits are remaining so we can calculate the efficiency with
        %high precision
       efficiency= ((file_size*length(binary_data)*8)/((number_of_packets*(length_total-1))+(remainder*payload*8)+(flag*29)))*100;
       efficiency_vector(loop_counter)=efficiency;
       
       overhead= 100-efficiency;
       overhead_vector(loop_counter)=overhead;
       
       tx_time=number_of_packets*0.0001*length_total;
       tx_vector(loop_counter)=tx_time;
       loop_counter=loop_counter+1;
    end
    
    %plotting of USB efficiency vs file size in bytes
    h1=figure(1);
    ax1 = axes('Parent', h1);
    plot(ax1,(1:0.3:5)*1280,efficiency_vector);
    xlabel(ax1,'file size in bytes');
    ylabel(ax1,'USB Efficiency');
    
    %plotting of USB overhead vs file size in bytes
    h2=figure(2);
    ax2=axes('parent',h2);
    plot(ax2,(1:0.3:5)*1280,overhead_vector);
    xlabel(ax2,'file size in bytes');
    ylabel(ax2,'USB Overhead');
    
    %plotting of USB transimission time vs file size in bytes
    
    h3=figure(3);
    ax3=axes('parent',h3);
    plot(ax3,(1:0.3:5)*1280,tx_vector);
    xlabel(ax3,'file size in bytes');
    ylabel(ax3,'USB Txtime');
   
     
     % preparing the first 2 packets for plotting
     plot_packet_vp=[first_packet,0,0,second_packet,0,0];%holds the +ve end of the first 2 packets
 
     first_packet_ne=zeros(1,length(first_packet));  % make the vector which will hold the -ve end of the first  packet
     second_packet_ne=zeros(1,length(second_packet));% make the vector which will hold the -ve end of the second  packet
     
     NZRI_frame_length=length(NZRI_frame);
     
     
     %*************making the +ve and -ve end  of the first 2 packets*********     
     
          for i = 1:(length(first_packet))
               if(first_packet(i) == 1)
                     first_packet_ne(i)=0;
               elseif(first_packet(i) ==0)
                     first_packet_ne(i)=1;
               end
          end
         
           for i = 1:(length(second_packet))
               if(second_packet(i) == 1)
                     second_packet_ne(i)=0;
               elseif(second_packet(i) ==0)
                     second_packet_ne(i)=1;
               end 
           end
         
     
     
     plot_packet_vn=[first_packet_ne,0,0,second_packet_ne,0,0]; %holds the -ve end of the first 2 packets
     ploted=plot_packet_vp(1:30);        % take the first 30 bits only to plot
     x=length(ploted);
     z=linspace(0,0.0001*x,x);  
     ploted_ne=plot_packet_vn(1:30);     % take the first 30 bits only to plot
     
     
     h4=figure(4);
     ax4=axes('parent',h4);
     stairs(ax4,z,ploted+1);        %plot the time diagram of the first 30 bits 
     ylim([-2 3]);
     hold on
     stairs(ax4,z,ploted_ne-1);     %plot the time diagram of the first 30 bits
     xlabel(ax4,'time');
     ylabel(ax4,'first 30 bits in USB transmission');
     
     x=length(plot_packet_vn);
     z=linspace(0,0.0001*x,x); 
     h8=figure(8);
     ax8=axes('parent',h8);
     stairs(ax8,z,plot_packet_vp+1);
     ylim([-2 3]);
     hold on
     stairs(ax8,z,plot_packet_vn-1);
     xlabel(ax8,'time');
     ylabel(ax8,'first 2 packets in USB transmission');


     
  %this segment of code is responsible for writing in the output file
  

 %*****************UART results parts
    UART_Struct = struct();
    UART_Struct.Protocolname = 'UART';
    UART_Struct.outputs.total_tx_time = UART_tx;
    UART_Struct.outputs.overhead =UART_overhead ;
    UART_Struct.outputs.efficiency = UART_efficiency;
 %*****************USB results parts
    USB_Struct  = struct();
    USB_Struct.Protocolname = 'USB';
    USB_Struct.outputs.total_tx_time = total_time_usb;
    USB_Struct.outputs.overhead = overhead_usb;
    USB_Struct.outputs.efficiency =efficiency_usb;

    OUT=fopen('ELC3030_47.json','w');

    fprintf(OUT,'%s','[' );
    UART_string=jsonencode(UART_Struct);

     UART_string = strrep(UART_string, "{", "{\n \t");
     UART_string = strrep(UART_string, ',', ',\n\t\t');
     UART_string = strrep(UART_string, "}", "\n \t}");
    fprintf(OUT,UART_string);

    fprintf(OUT,'%s\n',',');
    USB_string=jsonencode(USB_Struct);
     USB_string = strrep(USB_string, "{", "{\n \t");
     USB_string = strrep(USB_string, ',', ',\n\t\t');
     USB_string = strrep(USB_string, "}", "\n \t}");

    fprintf(OUT,USB_string);
    fprintf(OUT,'%s',']');
    fclose(OUT);
     
    end
