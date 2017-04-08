# Protocol Documentation
<a name="top"/>

## Table of Contents
* [karps.proto](#karps.proto)
 * [Computation](#karps.Computation)
 * [Node](#karps.Node)
 * [NodeComputationFailure](#karps.NodeComputationFailure)
 * [NodeComputationSuccess](#karps.NodeComputationSuccess)
 * [NodePath](#karps.NodePath)
 * [NodeQueued](#karps.NodeQueued)
 * [NodeRunning](#karps.NodeRunning)
 * [NodeStatus](#karps.NodeStatus)
 * [NodeLocality](#karps.NodeLocality)
* [op.proto](#op.proto)
 * [AggregationOperation](#karps.op.AggregationOperation)
 * [AggregationOperation.StructField](#karps.op.AggregationOperation.StructField)
 * [BroadcastJoin](#karps.op.BroadcastJoin)
 * [ColumnOperation](#karps.op.ColumnOperation)
 * [ColumnOperation.Extraction](#karps.op.ColumnOperation.Extraction)
 * [ColumnOperation.Function](#karps.op.ColumnOperation.Function)
 * [ColumnOperation.Literal](#karps.op.ColumnOperation.Literal)
 * [ColumnOperation.StructField](#karps.op.ColumnOperation.StructField)
 * [DistributedLiteral](#karps.op.DistributedLiteral)
 * [FieldPath](#karps.op.FieldPath)
 * [LocalLiteral](#karps.op.LocalLiteral)
 * [NodeOperation](#karps.op.NodeOperation)
 * [NodePointer](#karps.op.NodePointer)
 * [OpaqueAggregator](#karps.op.OpaqueAggregator)
 * [StandardOperator](#karps.op.StandardOperator)
 * [StructuredAggregationFunction](#karps.op.StructuredAggregationFunction)
 * [UDAFAggregation](#karps.op.UDAFAggregation)
* [op_extras.proto](#op_extras.proto)
* [service.proto](#service.proto)
 * [ComputationStatusRequest](#karps.ComputationStatusRequest)
 * [ComputationStatusResponse](#karps.ComputationStatusResponse)
 * [ComputationStatusResponse.Status](#karps.ComputationStatusResponse.Status)
 * [CreateComputationRequest](#karps.CreateComputationRequest)
 * [CreateComputationResponse](#karps.CreateComputationResponse)
 * [CreateSessionData](#karps.CreateSessionData)
 * [CreateSessionResult](#karps.CreateSessionResult)
 * [ResourceStatusRequest](#karps.ResourceStatusRequest)
 * [ResourceStatusRequest.Resource](#karps.ResourceStatusRequest.Resource)
 * [ResourceStatusResponse](#karps.ResourceStatusResponse)
 * [ResourceStatusResponse.ResourceError](#karps.ResourceStatusResponse.ResourceError)
 * [ResourceStatusResponse.ResourceInfo](#karps.ResourceStatusResponse.ResourceInfo)
 * [KarpsService](#karps.KarpsService)
* [types.proto](#types.proto)
 * [ArrayType](#karps.ArrayType)
 * [Cell](#karps.Cell)
 * [DataType](#karps.DataType)
 * [Row](#karps.Row)
 * [StructType](#karps.StructType)
 * [StructType.StructField](#karps.StructType.StructField)
 * [DataType.Primitive](#karps.DataType.Primitive)
* [Scalar Value Types](#scalar-value-types)

<a name="karps.proto"/>
<p align="right"><a href="#top">Top</a></p>

## karps.proto

General message structures.

<a name="karps.Computation"/>
### Computation
A computation sent to the backend.

A computation is a unit of work for the backend. It corresponds to a single
graph (DAG) of operations to perform.

All computations operate within a session, which is the unit of state in
the backend.

A computation defines a list of terminal nodes. It is declared to be
completed when all the terminal nodes have been evaluated.

If operations need to refer to results of previous operations, a special
pointer structure is provided.

| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| id | [string](#string) | optional | An identifier for this computation.Each identifier must be unique. An error will be triggered if theID of this computation has been already seen within the scope of thesession. |
| nodes | [Node](#karps.Node) | repeated | The compute nodes. They must form a DAG. |
| terminalNodes | [NodePath](#karps.NodePath) | repeated | The paths of the nodes that will be used to determine if the session hasfinished.Note: these nodes must be observables (not datasets). An error is triggeredotherwise.Note: if the list is empty, no computation is performed. |
| collectingNode | [string](#string) | optional | TODO: remove |
| terminalNodeIds | [string](#string) | repeated | TODO: remove |


<a name="karps.Node"/>
### Node
A computation node. Each node corresponds to an operator in a graph of
computations.

A node has a single output (unlike TensorFlow for example), which is either
'local' or 'distributed' (see the discussion in NodeLocality).

| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| locality | [NodeLocality](#karps.NodeLocality) | optional | The locality of the output. |
| path | [NodePath](#karps.NodePath) | optional | The path of this node in the computation. |
| op_name | [string](#string) | optional | The name of the operator.It is customary to use the java class convention when defining an operator.For example, all the standard Karps operators in defined in the`org.spark` and `org.karps` namespace: `org.spark.LocalLiteral`, etc. |
| op_extra | [Any](#google.protobuf.Any) | optional | Some extra information that is necessary for the operator to work. Thisfield is optional.For example, the extra values required by the operators in the standardlibrary are defined in `op.proto`. |
| parents | [NodePath](#karps.NodePath) | repeated | (optional) The dependencies of this operator. These nodes must be part ofthecomputation, and cannot form a cycle. An error is raised otherwise.This list may be empty or absent. |
| logical_dependencies | [NodePath](#karps.NodePath) | repeated | Extra dependencies that are not required by the operator to work, but thatwill be checked for completion before working on this operator.This is useful when strictly ordering operators that work as side effects,or to schedule computations at different times.If provided, Karps will always honor this ordering and not attempt tooptimize it away. |
| validation_type | [DataType](#karps.DataType) | optional | (optional) The data type of the value (for observable) or of the value (fordatasets).This type is not required, but it is useful to confirm that the typecomputed by the fronted corresponds to what the backend is going to produce. |


<a name="karps.NodeComputationFailure"/>
### NodeComputationFailure
The computation of this node has finished with a failure.

All children of this node will also be marked as failure (not logical ones).

Note that the backend should not cache failures.

| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| message | [string](#string) | optional |  |


<a name="karps.NodeComputationSuccess"/>
### NodeComputationSuccess
The computation of this node has finished with a success.

If requested, the content of this node is also returned.

| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| data_type | [DataType](#karps.DataType) | optional | The data type of the content. |
| value | [Cell](#karps.Cell) | optional | (optional) Returned if the node is an observable and if contents isrequested. |


<a name="karps.NodePath"/>
### NodePath
The path of a node from the root of the computation.

Each node in a computation is uniquely identified by a path, starting
from the computation object. The fact that it is a path in a tree
of nodes is entirely a user concept. For all practical matters, Karps
only assumes that each node is uniquely addressable.

If two nodes in the same computation are found to share the same path, an
error is returned.

The string in the path is assumed for now to only contain letters, digits, -
and _. Each name may not be empty. The list may not be empty.

Note: the global path (that includes the session id and the computation id)
is a separate data structure.

| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| path | [string](#string) | repeated |  |


<a name="karps.NodeQueued"/>
### NodeQueued
The node has been received and is awaiting processing.

| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |


<a name="karps.NodeRunning"/>
### NodeRunning
The node has been scheduled to run by the backend.

| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |


<a name="karps.NodeStatus"/>
### NodeStatus
The status of a node.

The status can be requested for both observables and datasets. However,
in the case of datasets, success and failure may never be returned (only
the start of the computation is registered).

Due to the optimizations performed by the query planner, requesting the
status of a dataset may be meaningless (this operator may be entirely 
optimized away by the planner).

| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| success | [NodeComputationSuccess](#karps.NodeComputationSuccess) | optional |  |
| failure | [NodeComputationFailure](#karps.NodeComputationFailure) | optional |  |
| queued | [NodeQueued](#karps.NodeQueued) | optional |  |
| running | [NodeRunning](#karps.NodeRunning) | optional |  |



<a name="karps.NodeLocality"/>
### NodeLocality
The locality of a compute node. This should be understood in the following
abstract sense.

A local node is observable. Its content can be retrieved by the user (in the 
form of a Cell object). It is subject to caching. It can be
refered to in subsequent computations through a Pointer.

A distributed node is not observable. Its content is not accessible.

Karps may elicit to entirely remove distributed nodes
as part of the query planning. Karps may elicit to perform 'distributed'
operations as single-computer operations if it determines it is faster: the
notion of 'local' and 'distributed' is abstract in this context.

Note: operations on grouped data

| Name | Number | Description |
| ---- | ------ | ----------- |
| LOCAL | 0 |  |
| DISTRIBUTED | 1 |  |




<a name="op.proto"/>
<p align="right"><a href="#top">Top</a></p>

## op.proto



<a name="karps.op.AggregationOperation"/>
### AggregationOperation


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| udaf | [UDAFAggregation](#karps.op.UDAFAggregation) | optional |  |
| structured_function | [StructuredAggregationFunction](#karps.op.StructuredAggregationFunction) | optional |  |
| struct | [AggregationOperation.StructField](#karps.op.AggregationOperation.StructField) | repeated |  |


<a name="karps.op.AggregationOperation.StructField"/>
### AggregationOperation.StructField


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| name | [string](#string) | optional |  |
| op | [AggregationOperation](#karps.op.AggregationOperation) | optional |  |


<a name="karps.op.BroadcastJoin"/>
### BroadcastJoin


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |


<a name="karps.op.ColumnOperation"/>
### ColumnOperation


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| extraction | [ColumnOperation.Extraction](#karps.op.ColumnOperation.Extraction) | optional |  |
| function | [ColumnOperation.Function](#karps.op.ColumnOperation.Function) | optional |  |
| literal | [ColumnOperation.Literal](#karps.op.ColumnOperation.Literal) | optional |  |
| struct | [ColumnOperation.StructField](#karps.op.ColumnOperation.StructField) | repeated |  |


<a name="karps.op.ColumnOperation.Extraction"/>
### ColumnOperation.Extraction


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| field_path | [FieldPath](#karps.op.FieldPath) | optional |  |


<a name="karps.op.ColumnOperation.Function"/>
### ColumnOperation.Function


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| name | [string](#string) | optional |  |
| arguments | [ColumnOperation](#karps.op.ColumnOperation) | repeated |  |


<a name="karps.op.ColumnOperation.Literal"/>
### ColumnOperation.Literal


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| value | [Cell](#karps.Cell) | optional |  |
| type | [DataType](#karps.DataType) | optional |  |


<a name="karps.op.ColumnOperation.StructField"/>
### ColumnOperation.StructField


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| name | [string](#string) | optional |  |
| op | [ColumnOperation](#karps.op.ColumnOperation) | optional |  |


<a name="karps.op.DistributedLiteral"/>
### DistributedLiteral


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| cellType | [DataType](#karps.DataType) | optional |  |
| values | [Cell](#karps.Cell) | repeated |  |


<a name="karps.op.FieldPath"/>
### FieldPath


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| field | [string](#string) | repeated |  |


<a name="karps.op.LocalLiteral"/>
### LocalLiteral


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| type | [DataType](#karps.DataType) | optional |  |
| value | [Cell](#karps.Cell) | optional |  |


<a name="karps.op.NodeOperation"/>
### NodeOperation


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| local_op | [StandardOperator](#karps.op.StandardOperator) | optional |  |
| local_literal | [LocalLiteral](#karps.op.LocalLiteral) | optional |  |
| distributed_literal | [DistributedLiteral](#karps.op.DistributedLiteral) | optional |  |
| opaque_aggregator | [OpaqueAggregator](#karps.op.OpaqueAggregator) | optional |  |
| broadcast | [BroadcastJoin](#karps.op.BroadcastJoin) | optional |  |
| structured_aggregation | [AggregationOperation](#karps.op.AggregationOperation) | optional |  |
| structured_transform | [ColumnOperation](#karps.op.ColumnOperation) | optional |  |
| pointer | [NodePointer](#karps.op.NodePointer) | optional |  |
| distributed_op | [StandardOperator](#karps.op.StandardOperator) | optional |  |


<a name="karps.op.NodePointer"/>
### NodePointer


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| path | [NodePath](#karps.NodePath) | optional |  |


<a name="karps.op.OpaqueAggregator"/>
### OpaqueAggregator


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| op | [StandardOperator](#karps.op.StandardOperator) | optional |  |


<a name="karps.op.StandardOperator"/>
### StandardOperator


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| name | [string](#string) | optional |  |
| extra | [Any](#google.protobuf.Any) | optional |  |
| output_type | [DataType](#karps.DataType) | optional |  |


<a name="karps.op.StructuredAggregationFunction"/>
### StructuredAggregationFunction


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| function_name | [string](#string) | optional |  |
| inputs | [FieldPath](#karps.op.FieldPath) | repeated |  |


<a name="karps.op.UDAFAggregation"/>
### UDAFAggregation


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |






<a name="op_extras.proto"/>
<p align="right"><a href="#top">Top</a></p>

## op_extras.proto







<a name="service.proto"/>
<p align="right"><a href="#top">Top</a></p>

## service.proto

Service definitions.

<a name="karps.ComputationStatusRequest"/>
### ComputationStatusRequest
The request for the status of a computation.

| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| session_id | [string](#string) | optional |  |
| computation_id | [string](#string) | optional |  |
| path | [string](#string) | repeated | A prefix that selects all or a subset of all the computation nodes. |


<a name="karps.ComputationStatusResponse"/>
### ComputationStatusResponse


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| status | [ComputationStatusResponse.Status](#karps.ComputationStatusResponse.Status) | repeated |  |


<a name="karps.ComputationStatusResponse.Status"/>
### ComputationStatusResponse.Status


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| path | [NodePath](#karps.NodePath) | optional |  |
| status | [NodeStatus](#karps.NodeStatus) | optional |  |


<a name="karps.CreateComputationRequest"/>
### CreateComputationRequest


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| session_id | [string](#string) | optional | The identifier of the session to run computations against. |
| computation | [Computation](#karps.Computation) | optional | The computation to run. |


<a name="karps.CreateComputationResponse"/>
### CreateComputationResponse


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |


<a name="karps.CreateSessionData"/>
### CreateSessionData
The data to create a new session.

| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| session_id | [string](#string) | optional |  |


<a name="karps.CreateSessionResult"/>
### CreateSessionResult


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |


<a name="karps.ResourceStatusRequest"/>
### ResourceStatusRequest
A request on some resources that are within the scope of a session and 
the server.

| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| paths | [ResourceStatusRequest.Resource](#karps.ResourceStatusRequest.Resource) | repeated |  |


<a name="karps.ResourceStatusRequest.Resource"/>
### ResourceStatusRequest.Resource


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| hdfs_path | [string](#string) | optional | A list of paths in HDFS. These are assumed to be URIs by the backend. |


<a name="karps.ResourceStatusResponse"/>
### ResourceStatusResponse


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| stamps | [ResourceStatusResponse.ResourceInfo](#karps.ResourceStatusResponse.ResourceInfo) | repeated | The result message with the resource stamps, or some errors. |


<a name="karps.ResourceStatusResponse.ResourceError"/>
### ResourceStatusResponse.ResourceError
An error that is returned if the backend cannot interrogate the given
resource.

| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| hint | [string](#string) | optional |  |


<a name="karps.ResourceStatusResponse.ResourceInfo"/>
### ResourceStatusResponse.ResourceInfo


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| resource_stamp | [string](#string) | optional |  |
| error | [ResourceStatusResponse.ResourceError](#karps.ResourceStatusResponse.ResourceError) | optional |  |





<a name="karps.KarpsService"/>
### KarpsService


| Method Name | Request Type | Response Type | Description |
| ----------- | ------------ | ------------- | ------------|
| CreateSession | [CreateSessionData](#karps.CreateSessionData) | [CreateSessionResult](#karps.CreateSessionResult) | Creates a new session on the server.An error is returned if a session already exists with the same name. |
| ResourceStatus | [ResourceStatusRequest](#karps.ResourceStatusRequest) | [ResourceStatusResponse](#karps.ResourceStatusResponse) | Inspects some existing resources to determine their 'freshness'.Given a list of resource descriptors (typically URIs), Karps returns someunique stamps that should respect the following invariant: if the contentof the resource has changed, then the stamp has changed.This is used by the optimizer to determine if some computations can bepruned and replaced with precached data. |
| CreateComputation | [CreateComputationRequest](#karps.CreateComputationRequest) | [CreateComputationResponse](#karps.CreateComputationResponse) | Creates a new computation for the given session. |
| ComputationStatus | [ComputationStatusRequest](#karps.ComputationStatusRequest) | [ComputationStatusResponse](#karps.ComputationStatusResponse) | Requests the status of some nodes of a computation. |


<a name="types.proto"/>
<p align="right"><a href="#top">Top</a></p>

## types.proto

Types and basic data structures.

This file defines the types of data, as understood in Karps. These data types
correspond to the data types found in SQL, Spark, etc., with some small
differences:

 - the unit of work is the cell, not the row.

 - a type is always associated with nullability information.

From a theoretical perspective, the types allowed by Karps are a subset of
the algebraic datatypes: all the product types are allowed, and the only
allowed sum type is Option/Maybe (nullability).

These changes allow a unified and well-defined treatment of datasets,
columns and observables without having to make exceptions for various corner
cases.

Meta-information is not allowed in types. It may be added eventually.

<a name="karps.ArrayType"/>
### ArrayType
An array of a given type.

| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| inner_type | [DataType](#karps.DataType) | optional |  |


<a name="karps.Cell"/>
### Cell
A cell.

A cell is a unit of content, checked by a data type.

If all the values below are empty, it is the empty cell.

The messages are brief to facilitate the reading.

| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| t | [string](#string) | optional |  |
| i | [int32](#int32) | optional |  |
| d | [double](#double) | optional |  |
| b | [bool](#bool) | optional |  |
| s | [Cell](#karps.Cell) | repeated | The content of a structure. |
| a | [Cell](#karps.Cell) | repeated | The content of an array. |


<a name="karps.DataType"/>
### DataType
The type of data stored in Karps.

| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| nullable | [bool](#bool) | optional | Nullability information. If set to nullable, the underlying value maybe missing. |
| primitive | [DataType.Primitive](#karps.DataType.Primitive) | optional |  |
| array | [ArrayType](#karps.ArrayType) | optional |  |
| struct | [StructType](#karps.StructType) | optional |  |


<a name="karps.Row"/>
### Row
A unit of content in Spark.

This is not used in Karps.

| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| cells | [Cell](#karps.Cell) | repeated |  |


<a name="karps.StructType"/>
### StructType
A structure. Unlike SQL, both the name and the order of the fields matter.

| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| fields | [StructType.StructField](#karps.StructType.StructField) | repeated | Note: unlike Spark, fields must be non-empty (no empty struct). |


<a name="karps.StructType.StructField"/>
### StructType.StructField
A field in a structure.

| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| name | [string](#string) | optional | Must be non-empty. Anything is allowed. |
| type | [DataType](#karps.DataType) | optional |  |



<a name="karps.DataType.Primitive"/>
### DataType.Primitive
The primitive data types.

| Name | Number | Description |
| ---- | ------ | ----------- |
| STRING | 0 |  |
| DOUBLE | 1 |  |
| INT | 2 | 32-bit encoding of signed integers. |
| BOOL | 3 |  |





<a name="scalar-value-types"/>
## Scalar Value Types

| .proto Type | Notes | C++ Type | Java Type | Python Type |
| ----------- | ----- | -------- | --------- | ----------- |
| <a name="double"/> double |  | double | double | float |
| <a name="float"/> float |  | float | float | float |
| <a name="int32"/> int32 | Uses variable-length encoding. Inefficient for encoding negative numbers – if your field is likely to have negative values, use sint32 instead. | int32 | int | int |
| <a name="int64"/> int64 | Uses variable-length encoding. Inefficient for encoding negative numbers – if your field is likely to have negative values, use sint64 instead. | int64 | long | int/long |
| <a name="uint32"/> uint32 | Uses variable-length encoding. | uint32 | int | int/long |
| <a name="uint64"/> uint64 | Uses variable-length encoding. | uint64 | long | int/long |
| <a name="sint32"/> sint32 | Uses variable-length encoding. Signed int value. These more efficiently encode negative numbers than regular int32s. | int32 | int | int |
| <a name="sint64"/> sint64 | Uses variable-length encoding. Signed int value. These more efficiently encode negative numbers than regular int64s. | int64 | long | int/long |
| <a name="fixed32"/> fixed32 | Always four bytes. More efficient than uint32 if values are often greater than 2^28. | uint32 | int | int |
| <a name="fixed64"/> fixed64 | Always eight bytes. More efficient than uint64 if values are often greater than 2^56. | uint64 | long | int/long |
| <a name="sfixed32"/> sfixed32 | Always four bytes. | int32 | int | int |
| <a name="sfixed64"/> sfixed64 | Always eight bytes. | int64 | long | int/long |
| <a name="bool"/> bool |  | bool | boolean | boolean |
| <a name="string"/> string | A string must always contain UTF-8 encoded or 7-bit ASCII text. | string | String | str/unicode |
| <a name="bytes"/> bytes | May contain any arbitrary sequence of bytes. | string | ByteString | str |
