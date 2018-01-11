


module.exports =  {


stringToSolidityBytes32(string)
{
  var result = "0x";
  var i = 0;

  for(i=0;i<32;i++)
  {
    if(string.length > i)
    {
      result += string.charCodeAt(i).toString(16)
    }else {
      result += "00"
    }
  }


  return result;
},

//0x6161000000000000000000000000000000000000000000000000000000000000 -> aa
solidityBytes32ToString(bytes32)
{
  var result = "";
  var i = 0;

  if(bytes32.startsWith('0x'))
  {
    var rawcodes = bytes32.substring(2);
  }else{
    var rawcodes = bytes32;
  }

  for(i=0;i<32;i++)
  {
    var segment = rawcodes.substring(i*2,i*2+2)
    var segment_value = parseInt(segment,16)
    if(segment_value != '00')
    {
      result += String.fromCharCode(segment_value)
    }
  }


  return result;
},
}
