[*back to contents*](https://github.com/gyuho/learn#contents)
<br>

# Go: protobuf

- [Reference](#reference)
- [Protocol buffers](#protocol-buffers)

[↑ top](#go-protobuf)
<br><br><br><br>
<hr>






#### Reference

- [*Protocal Buffers by Wikipedia*](https://en.wikipedia.org/wiki/Protocol_Buffers)
- [Protocal buffers](https://developers.google.com/protocol-buffers/)

[↑ top](#go-protobuf)
<br><br><br><br>
<hr>







#### Protocol buffers

> Protocol buffers are Google’s language-neutral, platform-neutral, extensible
> mechanism for **serializing structured data**— think XML, but smaller,
> faster, and simpler. You define how you want your data to be structured once,
> then you can use special generated source code to easily write and read your
> structured data to and from a variety of data streams and using a variety of
> languages.
>
> [*Protocol buffers*](https://developers.google.com/protocol-buffers/)

*Google* uses *protocol buffers* for storing and interchaning structured data
through RPCs. To install *Protocol buffers*:

```bash
#!/bin/bash
sudo apt-get install protobuf-compiler;
go get -v github.com/golang/protobuf/{proto,protoc-gen-go};

```


<br>
To define the structured data in *protocol buffer*:

```protobuf
// datapb.proto
package datapb;
	
enum FOO { X = 17; };
	
message SampleData {
	required string label = 1;
	optional int32 type = 2 [default=77];
	repeated int64 reps = 3;
	optional group OptionalGroup = 4 {
		required string RequiredField = 5;
	}
}

```

<br>
To compile *protocol buffer* into **_Go-compatible data structures**:

```bash
#!/bin/bash
cd /home/ubuntu/go/src/github.com/gyuho/learn/doc/go_protobuf/datapb;
protoc --go_out=. *.proto;
```

This outputs `datapb.pb.go`:

```go
// Code generated by protoc-gen-go.
// source: datapb.proto
// DO NOT EDIT!

/*
Package datapb is a generated protocol buffer package.

datapb.proto

It is generated from these files:
	datapb.proto

It has these top-level messages:
	SampleData
*/
package datapb

import proto "github.com/golang/protobuf/proto"
import math "math"

// Reference imports to suppress errors if they are not otherwise used.
var _ = proto.Marshal
var _ = math.Inf

type FOO int32

const (
	FOO_X FOO = 17
)

var FOO_name = map[int32]string{
	17: "X",
}
var FOO_value = map[string]int32{
	"X": 17,
}

func (x FOO) Enum() *FOO {
	p := new(FOO)
	*p = x
	return p
}
func (x FOO) String() string {
	return proto.EnumName(FOO_name, int32(x))
}
func (x *FOO) UnmarshalJSON(data []byte) error {
	value, err := proto.UnmarshalJSONEnum(FOO_value, data, "FOO")
	if err != nil {
		return err
	}
	*x = FOO(value)
	return nil
}

type SampleData struct {
	Label            *string                   `protobuf:"bytes,1,req,name=label" json:"label,omitempty"`
	Type             *int32                    `protobuf:"varint,2,opt,name=type,def=77" json:"type,omitempty"`
	Reps             []int64                   `protobuf:"varint,3,rep,name=reps" json:"reps,omitempty"`
	Optionalgroup    *SampleData_OptionalGroup `protobuf:"group,4,opt,name=OptionalGroup" json:"optionalgroup,omitempty"`
	XXX_unrecognized []byte                    `json:"-"`
}

func (m *SampleData) Reset()         { *m = SampleData{} }
func (m *SampleData) String() string { return proto.CompactTextString(m) }
func (*SampleData) ProtoMessage()    {}

const Default_SampleData_Type int32 = 77

func (m *SampleData) GetLabel() string {
	if m != nil && m.Label != nil {
		return *m.Label
	}
	return ""
}

func (m *SampleData) GetType() int32 {
	if m != nil && m.Type != nil {
		return *m.Type
	}
	return Default_SampleData_Type
}

func (m *SampleData) GetReps() []int64 {
	if m != nil {
		return m.Reps
	}
	return nil
}

func (m *SampleData) GetOptionalgroup() *SampleData_OptionalGroup {
	if m != nil {
		return m.Optionalgroup
	}
	return nil
}

type SampleData_OptionalGroup struct {
	RequiredField    *string `protobuf:"bytes,5,req" json:"RequiredField,omitempty"`
	XXX_unrecognized []byte  `json:"-"`
}

func (m *SampleData_OptionalGroup) Reset()         { *m = SampleData_OptionalGroup{} }
func (m *SampleData_OptionalGroup) String() string { return proto.CompactTextString(m) }
func (*SampleData_OptionalGroup) ProtoMessage()    {}

func (m *SampleData_OptionalGroup) GetRequiredField() string {
	if m != nil && m.RequiredField != nil {
		return *m.RequiredField
	}
	return ""
}

func init() {
	proto.RegisterEnum("datapb.FOO", FOO_name, FOO_value)
}

```

<br>
To read and write *protocol buffer* in Go:

```go
package main

import (
	"fmt"
	"log"

	"github.com/golang/protobuf/proto"

	"github.com/gyuho/learn/doc/go_protobuf/datapb"
)

func main() {
	d := &datapb.SampleData{
		Label: proto.String("hello"),
		Type:  proto.Int32(17),
		Optionalgroup: &datapb.SampleData_OptionalGroup{
			RequiredField: proto.String("good bye"),
		},
	}
	fmt.Println("d.GetLabel():", d.GetLabel())
	fmt.Println()
	// d.GetLabel(): hello

	data, err := proto.Marshal(d)
	if err != nil {
		log.Fatal("marshaling error: ", err)
	}
	fmt.Printf("data: %+v\n", data)
	fmt.Println()
	// data: [10 5 104 101 108 108 111 ...

	newD := &datapb.SampleData{}
	if err := proto.Unmarshal(data, newD); err != nil {
		log.Fatal("unmarshaling error: ", err)
	}
	fmt.Println("newD.GetLabel():", newD.GetLabel())
	fmt.Println()
	// newD.GetLabel(): hello

	fmt.Printf("newD: %+v\n", newD)
	// newD: label:"hello" type:17 OptionalGroup{RequiredField:"good bye" }
}

```

[↑ top](#go-protobuf)
<br><br><br><br>
<hr>