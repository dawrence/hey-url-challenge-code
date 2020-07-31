import React, { useState, useEffect } from 'react'

function Stats(props){
  const stats = props.stats
  const statsToggl = props.statsToggle;
  const statsId = props.statsId;

  if(!stats || statsId !== statsToggl) {
    return '';
  }
  else {
    return (
      <div>
        <p><strong> Clicks Per Day: </strong> { stats.clicks_per_day }</p>
        <p><strong> Browsers: </strong> { stats.browsers }</p>
        <p><strong> Platforms: </strong> { stats.platforms }</p>
      </div>
    );
  }
}

export default Stats;
