module.exports = async ({ github, context, header, body }) => {
    const comment = [header, body].join("\n");
  
    // Check if the workflow is triggered by a pull request event
    if (!context.payload.pull_request) {
        console.log('This workflow is not triggered by a pull request. Skipping comment creation/update.');
        return;
    }
  
    const { data: comments } = await github.rest.issues.listComments({
      owner: context.repo.owner,
      repo: context.repo.repo,
      issue_number: context.payload.pull_request.number,
    });
  
    const botComment = comments.find(
      comment => comment.user.type === 'Bot' && comment.body.startsWith(header)
    );
  
    const commentFn = botComment ? 'updateComment' : 'createComment';
  
    await github.rest.issues[commentFn]({
      owner: context.repo.owner,
      repo: context.repo.repo,
      body: comment,
      ...(botComment ? { comment_id: botComment.id } : { issue_number: context.payload.pull_request.number }),
    });
};
