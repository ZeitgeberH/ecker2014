function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    acq.getSchema();
    schemaObject = dj.Schema(dj.conn, 'detect', 'ecker2014_detect');
end
obj = schemaObject;
